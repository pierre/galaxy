package com.ning.galaxy.console.deployment;

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
}
