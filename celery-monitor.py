from celery import Celery
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import html2text
from netdelta import settings
from celmon_logger import log_crunch
import re

app_log = log_crunch()


def mailer(html, result, site):
    message_body = html

    sender = settings.ALERTS_SENDER
    mesg = MIMEMultipart('alternative')

    if result == "success":
        mesg['subject'] = "[" + site + "] Celery Job Successful"
    else:
        mesg['subject'] = "[" + site + "] Celery Job FAILED"

    mesg['From'] = sender
    # mesg['To'] = ", ".join(alert_recipients)
    # print(("message recipients are {0} of type {1}").format(mesg['To'], type(mesg['To'])))
    html = message_body
    plain_text = html2text.html2text(html)

    part_one = MIMEText(plain_text, 'plain')
    part_two = MIMEText(html, 'html')

    mesg.attach(part_one)
    mesg.attach(part_two)

    try:
        mail = smtplib.SMTP(settings.ALERTS_MAIL_SERVER + ':' + settings.SMTP_PORT)
        mail.ehlo()
        if settings.USE_SSL:
            mail.starttls()
        if settings.SMTP_USER_NAME:
            mail.login(settings.SMTP_USER_NAME, settings.SMTP_PASSWORD)
        mail.sendmail(mesg['from'], "ian.tibble@netdelta.io", mesg.as_string())
        mail.close()
        return "success"

    except smtplib.SMTPException as error:
        print(str(error), 'Failed!')
        return str(error)


def my_monitor(app):
    state = app.events.State()

    def announce_successful_tasks(event):
        state.event(event)
        # task name is sent only with -received event, and state
        # will keep track of this for us.
        task = state.tasks.get(event['uuid'])
        site = task.hostname.lstrip("celery@")
        task_info = task.info()
        group = str(task_info['args'])
        app_log.info("celery job finished successfully for site: {0} and group: {1}".format(site, group), group=group,
                     site=site)
        # print("task_info is {0} of type {1}".format(task_info, type(task_info)))
        # print("caught task-succeeded event: event is {0} of type {1}".format(event, type(event)))
        html = "<h2>Site: " + site + "</h2>"
        html += "<style>.green {color: #5b9b4e}</style>"
        html += "<h3>Group: " + group + "</h3>"
        html += "<h4><span class=\"green\">Celery job completed successfully</span></h4>"

        mailer(html, "success", site)

    def announce_failed_tasks(event):
        state.event(event)

        # task name is sent only with -received event, and state
        # will keep track of this for us.
        task = state.tasks.get(event['uuid'])
        site = task.hostname.lstrip("celery@")
        task_info = task.info()
        group = str(task_info['args'])

        e = re.sub("^", "<pre>", event['traceback'])
        f = re.sub("$", "</pre>", e)
        traceback_html = re.sub("\\n", "<br>", f)

        html = "<h2>Site: " + site + "</h2>"
        html += "<style>.red {color: #c11}</style>"
        html += "<h3>Group: " + group + "</h3>"
        html += "<h4><span class=\"red\">Celery job failed</span></h4>"
        html += "<p></p>"
        html += "<table border=\"1\">"
        html += "<tr><td><strong>Exception</strong></td><td>" + str(task_info['exception']) + "</td></tr>"

        html += "<tr><td><strong>Traceback</strong></td><td>" + traceback_html + "</td></tr>"
        app_log.info("Problem with celery job for site: {0} and group: {1}".format(site, group), group=group,
                     site=site, exception=task_info['exception'], traceback=event['traceback'])
        html += "</table>"

        mailer(html, "failed", site)

    #
    # def what_is_my_event(event):
    #     state.event(event)
    #     if event['type'] != "worker-heartbeat":
    #         print("caught event {0}".format(event['type']))

    with app.connection() as connection:
        # print("connection is {0} of type {1}".format(connection, type(connection)))
        # print("app is {0} of type {1}".format(app, type(app)))
        recv = app.events.Receiver(connection, handlers={
            'task-succeeded': announce_successful_tasks,
            'task-failed': announce_failed_tasks,
            '*': state.event,
        })
        recv.capture(limit=None, timeout=None, wakeup=True)


if __name__ == '__main__':
    app = Celery(broker='amqp://guest@localhost//')
    my_monitor(app)
