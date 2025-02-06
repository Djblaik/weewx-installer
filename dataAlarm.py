import logging
from pathlib import Path
import sqlite3
import threading
import time
import requests
from weewx.engine import StdService

log = logging.getLogger(__name__)


# Inherit from the base class StdService:
class dataAlarm(StdService):
    """Service that sends an nfty notification if no data is received for 'data_threshold' minutes"""

    def __init__(self, engine, config_dict):
        # Pass the initialization information on to my superclass:
        super().__init__(engine, config_dict)

        # This will hold the time when the last alarm message went out:
        self.last_msg_ts = 0

        try:
            # Dig the needed options out of the configuration dictionary.
            # If a critical option is missing, an exception will be raised and
            # the alarm will not be set.
            self.time_wait = int(config_dict["Alarm"].get("data_time_wait", 1800))
            self.data_threshold = int(config_dict["Alarm"]["data_threshold"])
            self.ALARMSUBJECT = config_dict["Alarm"].get(
                "subjectAlarms", "Alarm message from weewx"
            )
            self.nftyTopic = config_dict["Alarm"].get("nftyTopic")
            # self.db_path =
            self.db_path = str(
                Path("~/weewx-data/archive/weewx.sdb").expanduser().resolve()
            )
            log.info(self.db_path)
        except KeyError as e:
            log.info("No alarm set.  Missing parameter: %s", e)
        else:
            # If we got this far, it's ok to start checking data:
            self.check_latest_data()

            # Start the loop in a separate thread
            self.start_checking_data()

    def start_checking_data(self):
        """Start the loop to check the latest data periodically."""
        threading.Thread(target=self.check_data_loop, daemon=True).start()

    def check_data_loop(self):
        """Loop that checks for the latest data every 'data_threshold' minutes."""
        while True:
            time.sleep(int(self.data_threshold))
            self.check_latest_data()

    def check_latest_data(self):
        """This function is called on a loop evey 'data_threshold' minutes,
        retreives the date of the latest record in the database and
        checks time elapsed since last record and current time.
        """
        log.info("Data check initiated.")
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT dateTime FROM archive ORDER BY dateTime DESC LIMIT 1;"
            )
            latest_time = cursor.fetchone()

        # Check if a result was returned
        if latest_time:
            # Extract the first element of the tuple
            latest_time = float(latest_time[0])
        else:
            log.info("SQL query No records found.")

        # Check if the latest record is within the threshold
        if time.time() - latest_time > float(self.data_threshold):
            if abs(time.time() - self.last_msg_ts) >= self.time_wait:
                mins = int(self.data_threshold / 60)
                log.info(f"No data received for {mins} minutes, sending alert.")
                t = threading.Thread(target=dataAlarm.sound_the_alarm, args=(self, latest_time))
                t.start()
                self.last_msg_ts = time.time()

    def sound_the_alarm(self,latest_time):
        """This function is called when the alarm has been triggered."""

        # Get the time and convert to a string:
        timestamp = time.time()
        t_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(timestamp))
        lt_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(latest_time))
        # Log it in the system log:
        log.info("Alarm triggered, WS not sending data")
        log.info(f"Data has not been received since {lt_str}")

        msg_text = """
Alarm triggerd at %s.
Data has not been received since %s
        """ % (
            t_str,
            lt_str,
        )
        try:
            requests.post(
                f"https://ntfy.sh/{self.nftyTopic}",
                data=f"{self.ALARMSUBJECT}\n{msg_text}".encode(encoding="utf-8"),
                headers={
                    "Title": "Alert from weewx",
                    "Tags": "warning",
                },
            )
            # Log sending the notification:
            log.info("Alert notification sent.")
        except Exception as e:
            log.error("Send push notification failed: %s", e)
            raise




"""The following is for Testing."""

'''if __name__ == "__main__":
    """This section is used to test dataAlarm.py. It uses a record and alarm
    expression that are guaranteed to trigger an alert.

    You will need a valid weewx.conf configuration file with an [Alarm]
    section that has been set up as illustrated at the top of this file."""

    from optparse import OptionParser
    import weecfg
    import weeutil.logger

    usage = """Usage: python alarm.py --help
       python alarm.py [CONFIG_FILE|--config=CONFIG_FILE]

Arguments:

      CONFIG_PATH: Path to weewx.conf """

    epilog = """You must be sure the WeeWX modules are in your PYTHONPATH.
    For example:

    PYTHONPATH=/home/weewx/bin python alarm.py --help"""

    # Force debug:
    weewx.debug = 1

    # Create a command line parser:
    parser = OptionParser(usage=usage, epilog=epilog)
    parser.add_option(
        "--config",
        dest="config_path",
        metavar="CONFIG_FILE",
        help="Use configuration file CONFIG_FILE.",
    )
    # Parse the arguments and options
    (options, args) = parser.parse_args()

    try:
        config_path, config_dict = weecfg.read_config(options.config_path, args)
    except IOError as e:
        exit("Unable to open configuration file: %s" % e)

    print("Using configuration file %s" % config_path)

    # Set logging configuration:
    weeutil.logger.setup("wee_dataAlarm", config_dict)

    if "Alarm" not in config_dict:
        exit("No [Alarm] section in the configuration file %s" % config_path)

    # We need the main WeeWX engine in order to bind to the event,
    # but we don't need for it to completely start up. So get rid of all
    # services:
    config_dict["Engine"]["Services"] = {}
    # Now we can instantiate our slim engine, using the DummyEngine class...
    engine = weewx.engine.DummyEngine(config_dict)
    # ... and set the alarm using it.
    alarm = dataAlarm(engine, config_dict)

    # trigger the alarm:
    while True:
        alarm.check_latest_data()
        time.sleep(300)
'''
