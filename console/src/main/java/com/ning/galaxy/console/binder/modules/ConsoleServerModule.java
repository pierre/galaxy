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

package com.ning.galaxy.console.binder.modules;

import com.google.common.collect.ImmutableMap;
import com.google.inject.Binder;
import com.google.inject.Module;
import com.google.inject.servlet.ServletModule;
import com.ning.galaxy.console.binder.ConsoleContainer;
import com.ning.galaxy.console.binder.config.ConsoleConfig;
import com.ning.galaxy.console.deployment.DeploymentsStore;
import com.sun.jersey.api.core.PackagesResourceConfig;
import org.codehaus.jackson.jaxrs.JacksonJsonProvider;
import org.skife.config.ConfigurationObjectFactory;

public class ConsoleServerModule extends ServletModule
{
    @Override
    protected void configureServlets()
    {
        install(new Module()
        {
            @Override
            public void configure(Binder binder)
            {
                ConsoleConfig config = new ConfigurationObjectFactory(System.getProperties()).build(ConsoleConfig.class);
                binder.bind(ConsoleConfig.class).toInstance(config);
                binder.bind(DeploymentsStore.class).toInstance(new DeploymentsStore());

                // Plug-in Jersey
                bind(JacksonJsonProvider.class).asEagerSingleton();
            }
        });

        filter("/*").through(ConsoleContainer.class, ImmutableMap.of(
            PackagesResourceConfig.PROPERTY_PACKAGES, "com.ning.galaxy.console.endpoint"
        ));
    }
}
