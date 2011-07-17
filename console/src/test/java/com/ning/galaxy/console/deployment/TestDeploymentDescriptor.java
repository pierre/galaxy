package com.ning.galaxy.console.deployment;

// Mutable class for testing
public class TestDeploymentDescriptor extends DeploymentDescriptor
{
    public TestDeploymentDescriptor(final String agentId, final String configPath)
    {
        this.agent_id = agentId;
        this.config_path = configPath;
    }
}
