package com.base.service;

import java.util.List;
import java.util.Map;

import com.base.bean.NodeType;

public interface NodeTypeService {
	
	public void insert(NodeType nodeType);
	
	public void deleteById(int id);
	
	public void deleteByPId(int pid);
	
	public void update(NodeType nodeType);
	
	public List<NodeType> findAll(Map<String,Object> map);
	
	
}
