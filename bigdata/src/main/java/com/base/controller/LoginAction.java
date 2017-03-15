package com.base.controller;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;


@Controller
public class LoginAction {
//	@Resource(name="usersService")
//	private UsersService usersService;
//	@Resource(name="funcService")
//	private FuncService funcService;
//	
//	/**
//	 * 后台用户登录页面
//	 */
//	@RequestMapping(value="/login.do",method=RequestMethod.GET)
//	public String login(@ModelAttribute("users") Users users){
//		return "login";
//	}
//	/**
//	 * 后台用户登录处理
//	 * 2013-12-23
//	 * 下午11:56:50
//	 */
//	@SuppressWarnings("unchecked")
//	@RequestMapping(value="/login.do",method=RequestMethod.POST)
//	public String login(Users users,HttpServletRequest request,Model model){
//		String msg=usersService.findUsersByLoginNameAndPassword(request, users);
//		List<Func> rootfuncList=null;
//		List<Func> siteFuncList=null;
//		List leftList =null;
//		if(msg.trim().equals("")){
//			//获得顶部菜单项
//			rootfuncList=funcService.findRootFunc();
//			if(rootfuncList!=null && rootfuncList.size()>0){
//				for(int i=0;i<rootfuncList.size();i++){
//					if(rootfuncList.get(i).getName().equals("站点")){
//						//获取站点菜单下所有的子菜单
//						siteFuncList=funcService.findFuncByParid(rootfuncList.get(i).getId(),"1","");
//					}
//				}
//				//获取左侧列表的数据
//				leftList= funcService.findLeftList(siteFuncList);
//			}
//			
//			model.addAttribute("topList", rootfuncList);
//			model.addAttribute("leftList",leftList);
//			return "admin/index";
//		}else{
//			System.out.println("登录出现错误!");
//			return "login";
//		}
//	}
}
