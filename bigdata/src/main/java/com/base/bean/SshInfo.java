package com.base.bean;

import java.io.Serializable;
import java.util.Date;

public class SshInfo implements Serializable{
	
	private static final long serialVersionUID = 1L;
	
	private int id;
	private String ip;
	private String port;
	private String user;
	private String passwd;
	
	private String nodetype; //节点类型
	private String nodename; //服务名称
	
	private int rsakey;//是否配置ssh key（0：未设置，1：已设置，2：设置失败，默认0）
	private int installstatus;//安装状态（0：未初始化，1：正在安装，2：安装失败， 5：完成，默认0）',
	private Date createtime;
	private Date updatetime;
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getIp() {
		return ip;
	}
	public void setIp(String ip) {
		this.ip = ip;
	}
	public String getPort() {
		return port;
	}
	public void setPort(String port) {
		this.port = port;
	}
	public String getUser() {
		return user;
	}
	public void setUser(String user) {
		this.user = user;
	}
	public String getPasswd() {
		return passwd;
	}
	public void setPasswd(String passwd) {
		this.passwd = passwd;
	}
	public String getNodetype() {
		return nodetype;
	}
	public void setNodetype(String nodetype) {
		this.nodetype = nodetype;
	}
	public String getNodename() {
		return nodename;
	}
	public void setNodename(String nodename) {
		this.nodename = nodename;
	}
	public int getRsakey() {
		return rsakey;
	}
	public void setRsakey(int rsakey) {
		this.rsakey = rsakey;
	}
	public int getInstallstatus() {
		return installstatus;
	}
	public void setInstallstatus(int installstatus) {
		this.installstatus = installstatus;
	}
	public Date getCreatetime() {
		return createtime;
	}
	public void setCreatetime(Date createtime) {
		this.createtime = createtime;
	}
	public Date getUpdatetime() {
		return updatetime;
	}
	public void setUpdatetime(Date updatetime) {
		this.updatetime = updatetime;
	}
	
}
