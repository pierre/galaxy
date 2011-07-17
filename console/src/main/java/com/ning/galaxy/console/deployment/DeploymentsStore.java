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

import com.google.common.base.Predicate;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import org.apache.commons.lang.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// Naive implementation, we probably want some persistency here
public class DeploymentsStore
{
    private final Map<String, List<DeploymentDescriptor>> store = new LinkedHashMap<String, List<DeploymentDescriptor>>();

    public DeploymentsStore()
    {
    }

    public DeploymentsStore(final Map<String, List<DeploymentDescriptor>> otherStore)
    {
        this.store.putAll(otherStore);
    }

    public void addOrUpdate(final DeploymentDescriptor deployment)
    {
        if (store.get(deployment.getAgentId()) == null) {
            store.put(deployment.getAgentId(), new ArrayList<DeploymentDescriptor>());
        }

        store.get(deployment.getAgentId()).add(deployment);
    }

    public Map<String, List<DeploymentDescriptor>> getStore()
    {
        return store;
    }

    /**
     * Returns the output of galaxy show
     */
    @Override
    public String toString()
    {
        final StringBuilder builder = new StringBuilder();
        final Object[] agents = store.values().toArray();

        for (final Object agent : agents) {
            // Make sure the output is predictable for scripting purposes
            Arrays.sort(((List) agent).toArray());

            for (final Object deploymentObject : (List) agent) {
                final DeploymentDescriptor deployment = (DeploymentDescriptor) deploymentObject;
                builder.append(String.format("%-20s %-45s %-10s %-15s %-20s %-20s %-15s %-8s\n",
                    deployment.getAgentId(),
                    deployment.getConfigPath(),
                    deployment.getStatus(),
                    deployment.getBuild(),
                    deployment.getCoreType(),
                    deployment.getMachine(),
                    deployment.getAgentGroup(),
                    deployment.getAgentStatus()));
            }
        }

        return builder.toString();
    }

    public DeploymentsStore filterByAgentId(final String agentId)
    {
        if (StringUtils.isBlank(agentId)) {
            return this;
        }

        final Predicate<DeploymentDescriptor> filter = new Predicate<DeploymentDescriptor>()
        {
            @Override
            public boolean apply(final DeploymentDescriptor input)
            {
                return input.getAgentId().equals(agentId);
            }
        };

        return applyFilter(filter);
    }

    public DeploymentsStore filterByMachine(final String machine)
    {
        if (StringUtils.isBlank(machine)) {
            return this;
        }

        final Predicate<DeploymentDescriptor> filter = new Predicate<DeploymentDescriptor>()
        {
            @Override
            public boolean apply(final DeploymentDescriptor input)
            {
                return input.getMachine().equals(machine);
            }
        };

        return applyFilter(filter);
    }

    public DeploymentsStore filterByState(final String state)
    {
        if (StringUtils.isBlank(state)) {
            return this;
        }

        final Predicate<DeploymentDescriptor> filter = new Predicate<DeploymentDescriptor>()
        {
            @Override
            public boolean apply(final DeploymentDescriptor input)
            {
                return input.getStatus().equals(state);
            }
        };

        return applyFilter(filter);
    }

    public DeploymentsStore filterByAgentState(final String agentState)
    {
        if (StringUtils.isBlank(agentState)) {
            return this;
        }

        final Predicate<DeploymentDescriptor> filter = new Predicate<DeploymentDescriptor>()
        {
            @Override
            public boolean apply(final DeploymentDescriptor input)
            {
                return input.getAgentStatus().equals(agentState);
            }
        };

        return applyFilter(filter);
    }

    public DeploymentsStore filterByEnvVersionType(String env, String version, String type)
    {
        if (StringUtils.isBlank(env) && StringUtils.isBlank(version) && StringUtils.isBlank(type)) {
            return this;
        }

        if (StringUtils.isBlank(env)) {
            env = "[^/]+";
        }
        if (StringUtils.isBlank(version)) {
            version = "[^/]+";
        }
        if (StringUtils.isBlank(type)) {
            type = "[^/]+";
        }

        final Pattern pattern = Pattern.compile(String.format("^/%s/%s/%s$", env, version, type));
        final Predicate<DeploymentDescriptor> filter = new Predicate<DeploymentDescriptor>()
        {
            @Override
            public boolean apply(final DeploymentDescriptor input)
            {
                final Matcher m = pattern.matcher(input.getConfigPath());
                return m.matches();
            }
        };

        return applyFilter(filter);
    }

    private DeploymentsStore applyFilter(final Predicate<DeploymentDescriptor> filter)
    {
        final Map<String, List<DeploymentDescriptor>> newStore = new LinkedHashMap<String, List<DeploymentDescriptor>>();
        for (final String agent : store.keySet()) {
            final List<DeploymentDescriptor> descriptors = store.get(agent);
            final ImmutableList<DeploymentDescriptor> foundDeployments = ImmutableList.copyOf(Iterables.filter(descriptors, filter));
            if (foundDeployments.size() > 0) {
                newStore.put(agent, foundDeployments);
            }
        }

        return new DeploymentsStore(newStore);
    }
}
