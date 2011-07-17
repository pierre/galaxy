<%@ page import="com.ning.galaxy.console.deployment.DeploymentDescriptor" %>

<%--
  ~ Copyright 2010-2011 Ning, Inc.
  ~
  ~ Ning licenses this file to you under the Apache License, version 2.0
  ~ (the "License"); you may not use this file except in compliance with the
  ~ License.  You may obtain a copy of the License at:
  ~
  ~    http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  ~ WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
  ~ License for the specific language governing permissions and limitations
  ~ under the License.
  --%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8">
    <title>Galaxy console</title>
    <script type="text/javascript" src="/static/js/jquery-1.3.2.min.js"></script>
    <link rel="stylesheet" href="/static/css/global.css" type="text/css">
</head>
<body>

<div id="header">
    <div class="wrapper">
        <h1>Galaxy deployments</h1>
    </div>
</div>


<div id="main">
    <div id="resultsWrapper">
        <table>
            <jsp:useBean id="it"
                         type="com.ning.galaxy.console.deployment.DeploymentsStore"
                         scope="request">
            </jsp:useBean>

            <tr>
                <th>Agent url</th>
                <th>Core type</th>
                <th>Config path</th>
                <th>Build</th>
                <th>Status</th>
            </tr>
            <%
                for (final DeploymentDescriptor e : it.getDeployments()) {
            %>
            <tr>
                <td><%= e.getUrl() %>
                </td>
                <td><%= e.getCoreType() %>
                </td>
                <td><%= e.getConfigPath() %>
                </td>
                <td><%= e.getBuild() %>
                </td>
                <td><%= e.getStatus() %>
                </td>
            </tr>
            <%
                }
            %></table>

        <div style="clear:both;"></div>
    </div>
</div>
</body>
</html>
