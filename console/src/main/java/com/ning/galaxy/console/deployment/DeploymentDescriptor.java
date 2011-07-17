/*
 * Copyright 2010-2011 Ning, Inc.
 *
 * Ning licenses this file to you under the Apache License, version 2.0
 * (the "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

package com.ning.galaxy.console.deployment;

public class DeploymentDescriptor implements Comparable<DeploymentDescriptor>
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
    public String deployment_id;

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

    public String getDeploymentId()
    {
        // For backward compatibility: if there is no deployment_id,
        // the agent manages a single deployment
        if (deployment_id == null) {
            return agent_id;
        }
        return deployment_id;
    }

    @Override
    public int compareTo(final DeploymentDescriptor o)
    {
        if (!agent_id.equals(o.getAgentId())) {
            return agent_id.compareTo(o.getAgentId());
        }
        else {
            return deployment_id.compareTo(o.getDeploymentId());
        }
    }
}
