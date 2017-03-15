package com.base.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import org.apache.commons.configuration.Configuration;
import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.PropertiesConfiguration;
import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

public class PerlUtil {
	
	private static final Logger logger = Logger.getLogger(PerlUtil.class);
	
	private static String perl_home;
	private static String app_home;
	private static String install_hadoop;
	private static String hadoop_install_log;
	
	@SuppressWarnings("rawtypes")
	private volatile Enum install_state = InstallState.NOT_START; //安装状态
	
	private static long lastTimeFileSize; 
	private static String config_file = "bigdata.properties";//配置文件名称
	
	private static List<ReceiveLogDataEventListener> listeners = null;
	
	private PerlUtil(){}
	private static PerlUtil obj = null;
	
	public static synchronized PerlUtil getInstance(){
		if (obj == null) {
			obj = new PerlUtil();
			init();
		}
		return obj;
	}
	
	/**
	 * 初始化方法
	 */
	private static void init() {
		try {
			Configuration config = new PropertiesConfiguration(config_file);
			perl_home = config.getString("perl_install_dir");
			app_home = config.getString("pp_install_dir");
			hadoop_install_log = app_home+"/install.log";
			System.out.println(perl_home);
			install_hadoop = perl_home+"/bin/perl "+app_home+"/install_hadoop.pl";
			listeners = new ArrayList<ReceiveLogDataEventListener>();
		} catch (ConfigurationException e) {
			e.printStackTrace();
		}
	}

	/**
	 * 解析ip集合
	 * @param ips
	 * @return
	 */
	public List<String> fornodes(String ips){
		logger.info("执行命令："+ips);
		List<String> list = new ArrayList<String>();
		for (int i = 0; i < 20; i++) {
			list.add("192.168.0."+i);
		}
//		ProcessBuilder builder = new ProcessBuilder(perl_home+"/bin/fornodes ",ips);
//		Process process;
//		BufferedReader bufferedReader = null;
//		try {
//			process = builder.start();
//			int n = process.waitFor();
//			if (n == 0) {
//				bufferedReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
//				String [] array = null;
//				String line = bufferedReader.readLine();
//				if (StringUtils.isNotEmpty(line)) {
//					array = line.split(" ");
//					for (int i = 0; i < array.length; i++) {
//						list.add(array[i]);
//					}
//				}
//				logger.info("获取到ip数量："+list.size());
//			}else {
//				logger.error("执行命令<"+ips+">出错!");
//			}
//		} catch (IOException e) {
//			e.printStackTrace();
//		} catch (InterruptedException e) {
//			e.printStackTrace();
//		}finally{
//			if (bufferedReader!=null) {
//				try {
//					bufferedReader.close();
//				} catch (IOException e) {
//					e.printStackTrace();
//				}
//			}
//		}
		return list;
	}
	
	/**
	 * 开始安装
	 * @return
	 */
	public synchronized void start_install(){
		new Thread(new Runnable() {
			private Process proc = null;
			private BufferedReader br = null;
			private int result = -1;//执行命令返回结果值
			@Override
			public void run() {
				if (install_state == InstallState.NOT_START) {
					install_state = InstallState.RUNNING;
					logger.info("开始安装集群，请等待...");
					ReceiveLogData.getInstance().clearData();
					try {
						proc = Runtime.getRuntime().exec(install_hadoop);
						String str = "";
						br = new BufferedReader(new InputStreamReader(
								proc.getInputStream()));
						while ((str = br.readLine()) != null) {
							// logger.info("str: "+str);
						}
						result = proc.waitFor();
					} catch (IOException e) {
						e.printStackTrace();
					} catch (InterruptedException e) {
						e.printStackTrace();
					} finally {
						if(result == 0){
			            	logger.info("hadoop安装【"+install_hadoop+"】成功："+result);
			            	logger.info("开始初始化数据分析调度...");
//					        QuartzUtil.init();
			                logger.info("初始化数据分析调度成功...");
			                install_state = InstallState.INSTALL_SUCCESS; //设置成安装成功
			            }else{
			            	install_state = InstallState.INSTALL_FAIL;  //设置成安装失败
			            	logger.info("hadoop安装【"+install_hadoop+"】失败："+result); 
			            }
						try {
							br.close();
						} catch (IOException e) {
							e.printStackTrace();
						}
						proc.destroy();
					}
				}else{
					logger.warn("已经开始安装集群了,请在多等待会...");
				}
			}
		}).start();
	}
	
	/**
	 * 重置安装状态
	 */
	public void resetInstallState(){
		install_state = InstallState.NOT_START;
	}
	
	/**
	 * 注册监听
	 * @param listener
	 */
	public void addListener(ReceiveLogDataEventListener listener){
		listeners.add(listener);
	}
	
	/**
	 * 唤醒监听
	 * @param args
	 */
	public void notifyListener(List<String> list){
		for (ReceiveLogDataEventListener listener : listeners) {
			listener.processLogData(list);
		}
	}
	
	/**   
     * 实时输出日志信息   
     * @param logFile 日志文件   
     * @throws IOException   
     */    
    public void realtimeShowLog() throws IOException{     
        //指定文件可读可写
        final RandomAccessFile randomFile = new RandomAccessFile(new File(hadoop_install_log),"rw");     
        //启动一个线程每10秒钟读取新增的日志信息     
        final ScheduledExecutorService exec = Executors.newScheduledThreadPool(1);     
        exec.scheduleWithFixedDelay(new Runnable(){     
            public void run() { 
            	if(install_state == InstallState.RUNNING){
            		List<String> list = new ArrayList<String>();
            		logger.info("正在读取日志文件【"+hadoop_install_log+"】信息.....install.log............");
                    try {     
                        //获得变化部分的     
                        randomFile.seek(lastTimeFileSize);     
                        String tmp = "";   
                        String data = "";
                        while( (tmp = randomFile.readLine())!= null) { 
                        	data = new String(tmp.getBytes("ISO8859-1"));
                        	list.add(data);
                        }
                        if(list!=null && list.size()>0){
                        	notifyListener(list);
                        }
                        lastTimeFileSize = randomFile.length();     
                    } catch (IOException e) {     
                        throw new RuntimeException(e);     
                    }  
            	}else{
            		logger.info("集群已经安装完毕..停止输出日志线程exec.shutdown().....");
            		exec.shutdown();
            	}
            }     
        }, 5, 10, TimeUnit.SECONDS);     
    }
		
	/**
	 * 安装状态枚举
	 * @author hadoop
	 */
	public enum InstallState{
		NOT_START,//未开始
		RUNNING,//安装中
		INSTALL_SUCCESS,//安装完成
		INSTALL_FAIL;//安装失败
	}	
	
	public Enum getInstall_state() {
		return install_state;
	}

	public static void main(String[] args) {
//		PerlUtil.getInstance().addListener(ReceiveLogData.getInstance());
//		try {
//			PerlUtil.getInstance().realtimeShowLog();
//			List list = ReceiveLogData.getInstance().getData();
//			System.out.println("-----------------");
//			if(list!=null && list.size()>0){
//				System.out.println("data2222:"+list.get(0));
//			}
//		} catch (IOException e) {
//			e.printStackTrace();
//		}
		System.out.println(PerlUtil.getInstance().getInstall_state()+"");
	}
}
