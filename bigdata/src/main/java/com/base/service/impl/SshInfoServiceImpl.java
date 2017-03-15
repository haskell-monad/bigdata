package com.base.service.impl;

import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import com.base.bean.SshInfo;
import com.base.mapper.SshInfoMapper;
import com.base.service.SshInfoService;

@Service
public class SshInfoServiceImpl implements SshInfoService{
	
	@Resource
	private SshInfoMapper infoMapper;

	@Override
	public void insert(SshInfo info) {
		infoMapper.insert(info);
	}

	@Override
	public void update(SshInfo info) {
		infoMapper.update(info);
	}

	@Override
	public void deleteById(int id) {
		infoMapper.deleteById(id);
	}

	@Override
	public List<SshInfo> selectAll(Map<String,Object> map) {
		return infoMapper.selectAll(map);
	}

	@Override
	public List<SshInfo> selectAllGroupBy(Map<String, Object> map) {
		return infoMapper.selectAllGroupBy(map);
	}

}
