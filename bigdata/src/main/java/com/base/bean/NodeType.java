package com.base.bean;

public class NodeType {
	
	private int id;
	private int pid;
	private String name;
	
	public NodeType() {
		super();
	}
	public NodeType(int id, int pid, String name) {
		super();
		this.id = id;
		this.pid = pid;
		this.name = name;
	}
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public int getPid() {
		return pid;
	}
	public void setPid(int pid) {
		this.pid = pid;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	
}
