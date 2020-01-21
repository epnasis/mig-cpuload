from flask import Flask
from subprocess import Popen, PIPE
from socket import gethostname
from psutil import cpu_percent, cpu_count
from os import getenv
from time import sleep

REFRESH_SEC = 2
HOSTNAME = gethostname()
CPU_COUNT = cpu_count()
HEADER = '<html><head><title>{}</title><meta http-equiv="refresh" content="{}"></head><body>'.format(HOSTNAME, REFRESH_SEC)
FOOTER = ('<br><p><a href="/">Refresh</a> | <a href="/load">Generate load</a> | <a href="/stop">Stop load</a>'
         + ' | <a href="/harm">Make unhealthy</a> | <a href="/heal">Make healthy</a></body></html>')
GOBACK = "<br><p><a href='/'>Go back</a>"

app = Flask(__name__)
procs = []
healthy = True

@app.route("/")
def index():
  template = HEADER
  template += "<h1>Instance: %s</h1>" % HOSTNAME
  template += "<p><b>CPU Utilization:</b> %s%% (real-time)" % round(cpu_percent())
  template += "<p><b>Healthy:</b> %s" % healthy
  template += FOOTER
  return template

@app.route("/health")
def health():
  if healthy:
    return("I feel good today!" + GOBACK)
  else:
    return("I'm not healthy :(" + GOBACK, 500)

@app.route("/heal")
def heal():
  global healthy
  healthy = True
  return("I'm HEALTHY!!! :)" + GOBACK)

@app.route("/harm")
def harm():
  global healthy
  healthy = False
  return("I'm NOT healthy :(" + GOBACK)

@app.route("/load")
def load():
  print("Generating load for %s CPUs" % CPU_COUNT, flush=True)
  for i in range(CPU_COUNT):
    proc = Popen("cat /dev/urandom > /dev/null", shell=True)
    procs.append(proc)
    print("Started process PID %s" % proc.pid, flush=True)
  return("Generating CPU load..." + GOBACK)

@app.route("/stop")
def stop():
  while procs:
    proc = procs.pop()
    proc.kill()
    print("Killed process PID %s" % proc.pid, flush=True)
  return("Stopping CPU load..." + GOBACK)

if __name__ == '__main__':
  print("Starting...")

  try:
    init_delay = int(getenv('INIT_DELAY_SEC', 0))
  except ValueError:
    init_delay = 0

  if init_delay:
    print("Simulating initialization delay of %s seconds..." % init_delay)
    sleep(init_delay)
    print("End of initialization.")

  app.run(host='0.0.0.0', port=80)
