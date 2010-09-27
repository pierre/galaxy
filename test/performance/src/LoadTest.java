import java.text.MessageFormat;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import org.apache.http.HttpVersion;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.params.HttpProtocolParams;

public class LoadTest {
  static BlockingQueue<String> queue = new LinkedBlockingQueue<String>();

  static Thread createWorker(int workerId, final int agentId, final int totalRequests, final String url) {
    final MessageFormat messageFormat = new MessageFormat(
        "--- !ruby/object:OpenStruct\ntable:\n   "
            + ":agent_status: online\n   " + ":config_path: a/b/c\n   "
            + ":host: z{0}.company.com\n   "
            + ":url: druby://z{1}.company.com:4441\n   "
            + ":core_type: benchmark\n   " + ":eventType: galaxy\n   "
            + ":machine: m{2}.company.com\n   " + ":galaxy_version: 2.6.4\n   "
            + ":os: linux\n   " + ":galaxy_event_type: success");

    final String name = "Worker " + workerId;
    Thread thread = new Thread(name) {
      @Override
      public void run() {
        boolean success;
        for (int i = 0, j; i < totalRequests; i++) {
          success = false;
          try {
//            System.err.println(this.getName() + " : #" + (i + 1));
            System.out.print(".");
            HttpParams httpParams = new BasicHttpParams();
            HttpProtocolParams.setVersion(httpParams, HttpVersion.HTTP_1_1);
            HttpConnectionParams.setSoTimeout(httpParams, new Integer(30000));
            HttpConnectionParams.setConnectionTimeout(httpParams, new Integer(30000));
            HttpClient httpClient = new DefaultHttpClient(httpParams);
            HttpPost httpPost = new HttpPost(url);
            j = agentId + i;
            Object[] input = new Object[] { j , j, j };
            StringEntity entity = new StringEntity(messageFormat.format(input));
            httpPost.setEntity(entity);
            httpClient.execute(httpPost);
            httpClient.getConnectionManager().shutdown();
            success = true;
          } catch (Exception e) {
//            System.err.println(e.getLocalizedMessage());
          }
          finally {
            if (!success) {
              String msg = name + " #" + (i + 1);
//              System.err.println("retrying worker " + msg);
              try {
                queue.put(msg);
              } catch (InterruptedException e) {
                e.printStackTrace();
              }
            }
          }
        }
      }
    };
    return thread;
  }

  public static void main(String[] args) throws Exception {
    int agents = 1400;
    int concurrentRequests = 70;
    String gonsoleUrl = "http://localhost:4442";
    if (args.length == 1 && args[0].endsWith("-h")) {
      System.out.println("java -jar galaxy-loader.jar -g <gonsole url> -a <# of agents> -c <# concurrent requests>");
      System.exit(0);
    }
    for (int i = 1; i < args.length; i += 2) {
      if("-g".equals(args[i - 1].trim())) {
        gonsoleUrl = args[i].trim();
      }
      else if("-a".equals(args[i - 1].trim())) {
        agents = Integer.parseInt(args[i].trim());
      }
      else if("-c".equals(args[i - 1].trim())) {
        concurrentRequests = Integer.parseInt(args[i].trim());
      }
    }

    System.out.println("gonsole = " + gonsoleUrl + ", agents = " + agents + ", concurrent requests = " + concurrentRequests);
    int totalWorkers = concurrentRequests;
    int totalRequests = (int) Math.round(agents / (double) concurrentRequests);
    Thread[] workers = new Thread[totalWorkers];
    for (int i = 0, j; i < totalWorkers; i++) {
      j = (i + 1) * totalRequests;
      workers[i] = createWorker((i + 1), j, totalRequests, gonsoleUrl);
    }

    long time = System.currentTimeMillis();
    for (Thread thread : workers) {
      thread.start();
    }

    for (Thread thread : workers) {
      try {
        thread.join();
      } catch (InterruptedException e) {
      }
    }
    time = System.currentTimeMillis() - time;
//    for (String msg : queue) {
//      System.out.println(msg);
//    }
    System.out.println("\ntotal failures: " + queue.size());
    System.out.println("total run time: " + (time / (1000)) + " sec");
  }
}
