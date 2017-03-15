package com.base.controller;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang.StringUtils;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;

import com.base.bean.NodeType;
import com.base.bean.SshInfo;
import com.base.service.NodeTypeService;
import com.base.service.SshInfoService;
import com.base.util.Constants;
import com.base.util.Json;
import com.base.util.PerlUtil;
import com.base.util.ReceiveLogData;

@Controller
@RequestMapping("install")
public class InstallController {

	@Resource
	private NodeTypeService nodeTypeService;
	
	@Resource
	private SshInfoService sshInfoService;
	
	/**
	 * 进入到安装页面
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/index.do")
	public ModelAndView index(HttpServletRequest request,HttpServletResponse response){
		ModelAndView model = new ModelAndView();
		Map<String,Object> map = new HashMap<String, Object>();
		map.put("pid",0);
		List<NodeType> list = nodeTypeService.findAll(map);
		model.addObject("nodeTypes",list);
		
		model.setViewName("/install/install");
		return model;
	}
	
	/**
	 * 添加sshinfo信息
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/add.do",method=RequestMethod.POST)
	public ModelAndView add(HttpServletRequest request,HttpServletResponse response){
		String ips = request.getParameter("ip");
		String ports = request.getParameter("port");
		String users = request.getParameter("user");
		String passs = request.getParameter("pass");
		String nodetype = request.getParameter("nodetype");//应用名称
		String nodename = request.getParameter("nodename");//服务名称
		SshInfo sshInfo = new SshInfo();
		sshInfo.setIp(ips);
		sshInfo.setPort(ports);
		sshInfo.setUser(users);
		sshInfo.setPasswd(passs);
		sshInfo.setNodetype(nodetype);
		sshInfo.setNodename(nodename);
		sshInfo.setRsakey(0);
		sshInfo.setInstallstatus(0);
		sshInfo.setCreatetime(new Date());
		sshInfoService.insert(sshInfo);
		List<SshInfo> list = sshInfoService.selectAll(null);
		Json json = new Json();
		String str = json.toJson(list);
		System.out.println(str);
		request.setAttribute("rtState",Constants.RETURN_SUCCESS);
		request.setAttribute("rtData",str);
		request.setAttribute("rtMsg","添加数据成功");
		
		return new ModelAndView(Constants.JSON_PAGE_TEMPLATE);
	}
	
	/**
	 * 获取所有sshinfo信息
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/show.do")
	public ModelAndView show(HttpServletRequest request,HttpServletResponse response){
		List<SshInfo> list = sshInfoService.selectAll(null);
		Json json = new Json();
		String str = json.toJson(list);
		request.setAttribute("rtState",Constants.RETURN_SUCCESS);
		request.setAttribute("rtData",str);
		request.setAttribute("rtMsg","获取数据成功");
		
		return new ModelAndView(Constants.JSON_PAGE_TEMPLATE);
	}
	
	/**
	 * 删除sshinfo信息
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/del.do",method=RequestMethod.POST)
	public ModelAndView del(HttpServletRequest request,HttpServletResponse response){
		String ids = request.getParameter("id");
		if(StringUtils.isNotEmpty(ids)){
			sshInfoService.deleteById(Integer.parseInt(ids));
		}
		
		List<SshInfo> list = sshInfoService.selectAll(null);
		Json json = new Json();
		String str = json.toJson(list);
		request.setAttribute("rtState",Constants.RETURN_SUCCESS);
		request.setAttribute("rtData",str);
		request.setAttribute("rtMsg","删除数据成功");
		
		return new ModelAndView(Constants.JSON_PAGE_TEMPLATE);
	}
	
	/**
	 * 查询节点类型
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/findNodeType.do")
	public ModelAndView findNodeType(HttpServletRequest request,HttpServletResponse response){
		String pids = request.getParameter("pid");
		List<NodeType> list = null;
		if(StringUtils.isNotEmpty(pids)){
			Map<String,Object> map = new HashMap<String, Object>();
			map.put("pid",Integer.parseInt(pids));
			list = nodeTypeService.findAll(map);
		}
		Json json = new Json();
		String str = json.toJson(list);
		request.setAttribute("rtState",Constants.RETURN_SUCCESS);
		request.setAttribute("rtData",str);
		request.setAttribute("rtMsg","");
		return new ModelAndView(Constants.JSON_PAGE_TEMPLATE);
		
	}
	
	/**
	 * 获取第三步，拓扑图展示页面
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/step.do")
	public ModelAndView step(HttpServletRequest request,HttpServletResponse response){
		ModelAndView model = new ModelAndView();
		Map<String,Object> map = new HashMap<String, Object>();
		map.put("pid",1);
		List<NodeType> list = nodeTypeService.findAll(map);
		List<String> keys = new ArrayList<String>();
		String name = "";
		String ips = "";
		List<String> ip_list = null;
		List<SshInfo> infolist = null;
		for (NodeType nodeType : list) {
			name = nodeType.getName();
			keys.add(name);
			map.clear();
			map.put("nodetype","Hadoop");
			map.put("nodename",name);
			infolist = sshInfoService.selectAll(map);
			if (infolist!=null && infolist.size()>0) {
				ips = infolist.get(0).getIp();
				ip_list = PerlUtil.getInstance().fornodes(ips);
				model.addObject("Hadoop_"+name,new Json().toJson(ip_list));
			}
		}
		model.addObject("Hadoop",new Json().toJson(keys));
		model.setViewName("/install/step3");
		return model;
	}
	
	
	/**
	 * 开始安装并获取安装日志
	 * @param request
	 * @param response
	 * @return
	 */
	@RequestMapping(value="/install")
	public ModelAndView install(HttpServletRequest request,HttpServletResponse response){
		if (PerlUtil.getInstance().getInstall_state() == PerlUtil.InstallState.NOT_START) {
			//没有开始安装则开始安装
			PerlUtil.getInstance().start_install();
			try {
				PerlUtil.getInstance().realtimeShowLog();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		//读取安装日志
		String data = "";
		List<String> list = ReceiveLogData.getInstance().getData();
		Json json = new Json();
		Map<String,String> map = null;
		List<Map<String,String>> array = new ArrayList<Map<String,String>>();
		if(list!=null && list.size()>0){
			for(int i =0;i<list.size();i++){
				map = new HashMap<String,String>();
				String str = list.get(i);
				map.put("datas",str);
				array.add(map);
			}
		}
		data = json.toJson(array);
		request.setAttribute("rtState",Constants.RETURN_SUCCESS);
		request.setAttribute("rtData",data);
		request.setAttribute("rtMsg",PerlUtil.getInstance().getInstall_state()+"");
		return new ModelAndView(Constants.JSON_PAGE_TEMPLATE);
	}
	
}
