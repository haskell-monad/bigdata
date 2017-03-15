package com.base.util;

import java.util.ArrayList;
import java.util.List;


/**
 * 接收数据监听器
 * @author hadoop
 */
public class ReceiveLogData implements ReceiveLogDataEventListener{
	
	private ReceiveLogData(){}
	private static ReceiveLogData obj = null;
	private static List<String> list = null;
	public static synchronized ReceiveLogData getInstance(){
		if (obj == null) {
			obj = new ReceiveLogData();
			list = new ArrayList<String>();
		}
		return obj;
	}
	
	@Override
	public void processLogData(List<String> list) {
		this.list.addAll(list);
	}
	
	/**
	 * 获取数据
	 * @return
	 */
	public List<String> getData(){
		return list;
	}
	
	/**
	 * 清空数据
	 */
	public void clearData(){
		list.clear();
	}

}
