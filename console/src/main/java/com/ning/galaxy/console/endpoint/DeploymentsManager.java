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
import com.ning.galaxy.console.deployment.DeploymentDescriptor;
import com.ning.galaxy.console.deployment.DeploymentsStore;
import com.sun.jersey.api.view.Viewable;
import org.apache.log4j.Logger;
import org.yaml.snakeyaml.TypeDescription;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;
import java.io.IOException;

@Path("/rest/1.0/deployment")
public class DeploymentsManager
{
    private static final Logger log = Logger.getLogger(DeploymentsManager.class);
    private final Yaml yaml = new Yaml(new Constructor(new TypeDescription(DeploymentDescriptor.class)));
    private final DeploymentsStore store;

    @Inject
    public DeploymentsManager(final DeploymentsStore store)
    {
        this.store = store;
    }

    @GET
    @Produces({"text/html"})
    public Viewable getAllDeployments() throws IOException
    {
        return new Viewable("/rest/listing.jsp", store);
    }

    @POST
    public Response processAnnouncement(final String descriptorYaml)
    {
        log.debug("Got ping: " + descriptorYaml);
        final DeploymentDescriptor descriptor = (DeploymentDescriptor) yaml.load(descriptorYaml);
        store.addOrUpdate(descriptor);
        return Response.ok().build();
    }
}
