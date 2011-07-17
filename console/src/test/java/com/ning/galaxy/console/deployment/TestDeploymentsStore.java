package com.ning.galaxy.console.deployment;

import org.testng.Assert;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TestDeploymentsStore
{
    final Map<String, List<DeploymentDescriptor>> deployments = new HashMap<String, List<DeploymentDescriptor>>();
    private DeploymentsStore store;

    @BeforeMethod
    public void setUp() throws Exception
    {
        // One agent with two deployments
        List<DeploymentDescriptor> frontCollectorsDeployment = new ArrayList<DeploymentDescriptor>();
        frontCollectorsDeployment.add(new TestDeploymentDescriptor("127.0.0.1", "/qa/15.0/coll/front"));
        frontCollectorsDeployment.add(new TestDeploymentDescriptor("127.0.0.1", "/qa/15.0/coll/front"));
        deployments.put("agent_1", frontCollectorsDeployment);

        // Another agent with a single deployment
        List<DeploymentDescriptor> backCollectorsDeployment = new ArrayList<DeploymentDescriptor>();
        backCollectorsDeployment.add(new TestDeploymentDescriptor("10.1.2.3", "/qa/15.0/coll/back"));
        deployments.put("agent_2", backCollectorsDeployment);

        // Another agent with a single deployment
        List<DeploymentDescriptor> collectorsDeployment = new ArrayList<DeploymentDescriptor>();
        collectorsDeployment.add(new TestDeploymentDescriptor("1.1.1.1", "/qa/15.0/coll"));
        deployments.put("agent_3", collectorsDeployment);

        store = new DeploymentsStore(deployments);
    }

    @Test(groups = "fast")
    public void testFilterByAgentId() throws Exception
    {
        DeploymentsStore filteredStore = store.filterByAgentId("127.0.0.1");

        // Only 1 agent should match
        Assert.assertEquals(filteredStore.getStore().values().size(), 1);

        // Only 2 deployments should match
        Assert.assertEquals(filteredStore.getStore().get("agent_1").size(), 2);
        Assert.assertNull(filteredStore.getStore().get("agent_2"));
        Assert.assertNull(filteredStore.getStore().get("agent_3"));
    }

    @Test(groups = "fast")
    public void testFilterByTypeAll() throws Exception
    {
        DeploymentsStore filteredStore = store.filterByEnvVersionType(null, null, "coll.*");

        // All 3 agents should match
        Assert.assertEquals(filteredStore.getStore().values().size(), 3);

        // All 4 deployments should match
        Assert.assertEquals(filteredStore.getStore().get("agent_1").size(), 2);
        Assert.assertEquals(filteredStore.getStore().get("agent_2").size(), 1);
        Assert.assertEquals(filteredStore.getStore().get("agent_3").size(), 1);

    }

    @Test(groups = "fast")
    public void testFilterByTypeFront() throws Exception
    {
        DeploymentsStore filteredStore = store.filterByEnvVersionType(null, null, "coll/front");

        // Only 1 agent should match
        Assert.assertEquals(filteredStore.getStore().values().size(), 1);

        // Only 2 deployments should match
        Assert.assertEquals(filteredStore.getStore().get("agent_1").size(), 2);
        Assert.assertNull(filteredStore.getStore().get("agent_2"));
        Assert.assertNull(filteredStore.getStore().get("agent_3"));
    }

    @Test(groups = "fast")
    public void testFilterByTypeBack() throws Exception
    {
        DeploymentsStore filteredStore = store.filterByEnvVersionType(null, null, "coll/back");

        // Only 1 agent should match
        Assert.assertEquals(filteredStore.getStore().values().size(), 1);

        // Only 1 deployment should match
        Assert.assertNull(filteredStore.getStore().get("agent_1"));
        Assert.assertEquals(filteredStore.getStore().get("agent_2").size(), 1);
        Assert.assertNull(filteredStore.getStore().get("agent_3"));
    }

    @Test(groups = "fast")
    public void testFilterByType() throws Exception
    {
        DeploymentsStore filteredStore = store.filterByEnvVersionType(null, null, "coll");

        // Only 1 agent should match
        Assert.assertEquals(filteredStore.getStore().values().size(), 1);

        // Only 1 deployment should match
        Assert.assertNull(filteredStore.getStore().get("agent_1"));
        Assert.assertNull(filteredStore.getStore().get("agent_2"));
        Assert.assertEquals(filteredStore.getStore().get("agent_3").size(), 1);
    }
}
