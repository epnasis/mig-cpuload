from flask import Flask
from subprocess import Popen, PIPE
from socket import gethostname
from psutil import cpu_percent, cpu_count

REFRESH_SEC = 2
HOSTNAME = gethostname()
CPU_COUNT = cpu_count()
HEADER = '<html><head><title>{}</title><meta http-equiv="refresh" content="{}"></head><body>'.format(HOSTNAME, REFRESH_SEC)
FOOTER = '<br><p><a href="/">Refresh</a> | <a href="/load">Generate load</a> | <a href="/stop">Stop load</a></body></html>'

app = Flask(__name__)

@app.route("/")
@app.route("/index")
def index():
  template = HEADER + "<h1>Instance: {}</h1><p><b>CPU Utilization:</b> {}% (real-time)" + FOOTER
  cpu_util = round(cpu_percent())
  return template.format(HOSTNAME, cpu_util)

@app.route("/load")
def load():
  print("Generating load for %s CPUs" % str(CPU_COUNT), flush=True)
  for i in range(CPU_COUNT):
    print("Starting process %s" % str(i+1), flush=True)
    Popen("cat /dev/urandom > /dev/null", shell=True)
  return "Generating CPU load...<br><p><a href='/'>Go back</a>"

@app.route("/stop")
def stop():
  Popen("killall cat", shell=True)
  return "Stopping CPU load...<br><p><a href='/'>Go back</a>"

if __name__ == '__main__':
    print("Starting...")
    app.run(host='0.0.0.0', port=80)
