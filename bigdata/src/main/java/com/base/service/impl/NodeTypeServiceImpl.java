package com.base.service.impl;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import com.base.bean.NodeType;
import com.base.mapper.NodeTypeMapper;
import com.base.service.NodeTypeService;


@Service
public class NodeTypeServiceImpl implements NodeTypeService {
	
	@Resource
	private NodeTypeMapper nodeTypeMapper;
	
	@Override
	public void insert(NodeType nodeType) {
		nodeTypeMapper.insert(nodeType);
	}

	@Override
	public void deleteById(int id) {
		nodeTypeMapper.deleteById(id);
	}
	
	@Override
	public void deleteByPId(int pid) {
		nodeTypeMapper.deleteByPId(pid);
	}

	@Override
	public void update(NodeType nodeType) {
		nodeTypeMapper.update(nodeType);
	}

	@Override
	public List<NodeType> findAll(Map<String,Object> map) {
		return nodeTypeMapper.findAll(map);
	}

}
