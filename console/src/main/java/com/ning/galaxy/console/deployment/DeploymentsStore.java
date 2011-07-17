package com.ning.galaxy.console.deployment;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;

// Naive implementation, we probably want some persistency here
public class DeploymentsStore
{
    private final Map<String, DeploymentDescriptor> store = new LinkedHashMap<String, DeploymentDescriptor>();

    public void add(DeploymentDescriptor deployment)
    {
        store.put(deployment.getAgentId(), deployment);
    }

    public Map<String, DeploymentDescriptor> getStore()
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
        Object[] deployments = store.values().toArray();
        // Make sure the output is predictable for scripting purposes
        Arrays.sort(deployments);

        for (Object deploymentObject : deployments) {
            DeploymentDescriptor deployment = (DeploymentDescriptor) deploymentObject;
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

        return builder.toString();
    }
}
