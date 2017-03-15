package com.base.mapper;

import java.util.List;
import java.util.Map;

import com.base.bean.SshInfo;

public interface SshInfoMapper {
	
	public void insert(SshInfo info);
	
	public void update(SshInfo info);

	public void deleteById(int id);
	
	public List<SshInfo> selectAll(Map<String,Object> map);
	
	public List<SshInfo> selectAllGroupBy(Map<String,Object> map);
	
}
