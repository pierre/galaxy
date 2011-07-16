package com.ning.galaxy.console.deployment;

public class DeploymentDescriptor
{
    // These attributes are sent for each ping.
    // We match the case of the ruby payload, but have appropriate
    // CamelCased getters.

    // Galaxy 2.5.1
    public String agent_id;
    public String agent_group;
    public String url;
    public String os;
    public String machine;
    public String core_type;
    public String config_path;
    public String build;
    public String status;
    public String last_start_time;
    public String agent_status;
    public String galaxy_version;

    // Galaxy 3.x.x
    public String slot_info;

    public String getAgentGroup()
    {
        return agent_group;
    }

    public String getAgentId()
    {
        return agent_id;
    }

    public String getAgentStatus()
    {
        return agent_status;
    }

    public String getBuild()
    {
        return build;
    }

    public String getConfigPath()
    {
        return config_path;
    }

    public String getCoreType()
    {
        return core_type;
    }

    public String getGalaxyVersion()
    {
        return galaxy_version;
    }

    public String getLastStartTime()
    {
        return last_start_time;
    }

    public String getMachine()
    {
        return machine;
    }

    public String getOs()
    {
        return os;
    }

    public String getSlotInfo()
    {
        return slot_info;
    }

    public String getStatus()
    {
        return status;
    }

    public String getUrl()
    {
        return url;
    }
}
