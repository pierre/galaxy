package com.ning.galaxy.console.deployment;

import com.ning.http.client.AsyncCompletionHandler;
import com.ning.http.client.AsyncHttpClient;
import com.ning.http.client.AsyncHttpClientConfig;
import com.ning.http.client.Response;
import org.apache.log4j.Logger;
import org.yaml.snakeyaml.TypeDescription;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class AgentApi
{
    private static final Logger log = Logger.getLogger(AgentApi.class);
    private static final String AGENT_PATH = "/rest/1.0/deployment";
    private static final String CONFIG_KEY = "config_path";
    private static String DEPLOYMENT_ID_KEY = "id";

    private final Yaml yaml = new Yaml(new Constructor(new TypeDescription(Map.class)));
    private final Map<String, String> assignment = new HashMap<String, String>(1);

    private AsyncHttpClient client;

    public AgentApi()
    {
        client = createHttpClient();
        assignment.put(CONFIG_KEY, "");
    }

    public String assign(final String agentURI, final String config) throws ExecutionException, InterruptedException
    {
        assignment.put(CONFIG_KEY, config);

        try {
            Map<String, Object> response = client.preparePost(String.format("%s/%s", agentURI, AGENT_PATH))
                .setBody(yaml.dump(assignment))
                .execute(new AsyncCompletionHandler<Map<String, Object>>()
                {
                    @Override
                    public Map<String, Object> onCompleted(final Response response) throws Exception
                    {
                        if (response.getStatusCode() != 200) {
                            return null;
                        }

                        return (Map<String, Object>) yaml.load(response.getResponseBody());
                    }

                    @Override
                    public void onThrowable(final Throwable t)
                    {
                        log.warn(String.format("Exception assigning %s to %s", agentURI, config), t);
                    }
                }).get();

            log.debug(String.format("Response from agent after assignment: %s", response));

            return (String) response.get(DEPLOYMENT_ID_KEY);
        }
        catch (IOException e) {
            log.warn(String.format("Exception contacting the agent: %s", agentURI), e);
        }

        return null;
    }

    private static AsyncHttpClient createHttpClient()
    {
        // Don't limit the number of connections per host
        // See https://github.com/ning/async-http-client/issues/issue/28
        final AsyncHttpClientConfig.Builder builder = new AsyncHttpClientConfig.Builder();
        builder.setMaximumConnectionsPerHost(-1);
        return new AsyncHttpClient(builder.build());
    }

    /**
     * Close the underlying http client
     */
    public synchronized void close()
    {
        client.close();
    }
}
