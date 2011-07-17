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

package com.ning.galaxy.console.endpoint;

import com.google.inject.Inject;
import com.ning.galaxy.console.deployment.DeploymentsStore;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;

// Use for interaction with the command line client
@Path("/rest/1.0/agent")
public class AgentsManager
{
    private final DeploymentsStore store;

    @Inject
    public AgentsManager(final DeploymentsStore store)
    {
        this.store = store;
    }

    /**
     * @return output of galaxy show
     */
    @GET
    @Produces({"text/plain"})
    public String getAllDeployments(@QueryParam("env") final String env,
                                    @QueryParam("version") final String version,
                                    @QueryParam("type") final String type,
                                    @QueryParam("agent_id") final String agentId,
                                    @QueryParam("machine") final String machine,
                                    @QueryParam("state") final String state,
                                    @QueryParam("agent_state") final String agentState)
    {
        return store
            .filterByAgentId(agentId)
            .filterByMachine(machine)
            .filterByState(state)
            .filterByAgentState(agentState)
            .filterByEnvVersionType(env, version, type)
            .toString();
    }
}
