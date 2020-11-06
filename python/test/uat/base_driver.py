""" Base class to use to test the Pennyworth web interface. """

from dataclasses import dataclass
from time import time

from selenium.common.exceptions import NoSuchElementException, TimeoutException
from seleniumbase import BaseCase
from seleniumbase.config.settings import (MINI_TIMEOUT,
                                          SMALL_TIMEOUT,
                                          LARGE_TIMEOUT,
                                          EXTREME_TIMEOUT)

import locators


class BaseDriver(BaseCase):
    """ Extends the seleniumbase BaseCase with extra helper functions specific to the Pennyworth web interface. """

    URL_ENVIRONMENT_MAP = {
        'local': 'http://localhost/',
        'dev': ''
        'sandbox': ''
    }

    @dataclass
    class Credentials:
        """ Dataclass for storing pennyworth user credentials. """
        username: str
        password: str
        passhash: str

    stage = None
    use_auth = None

    USERS_MAP = {}
    USER_IDS = {}


    def __init__(self, *args, **kwargs):
        super(BaseDriver, self).__init__(*args, **kwargs)

    def tearDownScreenshot(self):
        """
        Used to still save screenshots on failure/end of tests
        while reusing a driver for multiple test methods.
        """
        self.save_teardown_screenshot()

    def tearDownDriver(self):
        """ Used to fully tear down the driver after it runs through multiple test methods. """
        super(BaseDriver, self).tearDown()

    def base_method(self):
        """ Needed for the `driver` fixture in conftest.py to utilize certain SeleniumBase features properly. """


    def get_to_home_page(self):
        """ Navigates to the home page for the current environment. """
        self.open(self.URL_ENVIRONMENT_MAP[self.stage])

    def login(self):
        """ Logs in as a valid Pennyworth user and clears the workspace if it's not empty. """
        # TODO: Automate login process
        pass

    def authenticate(self, user_type):
        """
        Authenticate the user via OTP token.

        Args:
        user_type -- the type of user trying to authenticate
        """
        # TODO: Automate authentication process
        pass

    def logout(self):
        """ Logs the current user out. """
        # TODO: Automate logout process
        pass

    def wait_for_url_to_change(self, url, timeout=LARGE_TIMEOUT):
        """
        Waits for the URL to be different from the given URL.

        Args:
        url -- the original URL expected to change
        timeout -- how long to wait for the URL to change
        """
        time_started = time()
        time_taken = 0
        while time_taken < timeout:
            curr_url = self.get_current_url()
            if curr_url != url:
                return
            time_taken = time() - time_started
        raise TimeoutException(f'URL did not change from {url} in {timeout} seconds.')
