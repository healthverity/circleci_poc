""" Pytest configuration and fixtures for Pennyworth UAT. """

from contextlib import contextmanager

import pytest
from seleniumbase import config as sb_config

from base_driver import BaseDriver
import db
import locators


def pytest_addoption(parser):
    """ Adds custom options.  """
    parser.addoption('--stage', '--s',
                     action='store',
                     dest='stage',
                     choices=('local', 'dev', 'sandbox'),
                     default='local',
                     type=str,
                     help='The pennyworth environment to run against.')
    parser.addoption('--use-authentication', '--use-auth', '--auth', '--a',
                     action='store_true',
                     dest='use_auth',
                     default=False,
                     help='Uses the authentication process when logging in.')
    parser.addoption('--use-database', '--udb', '--db',
                     action='store_true',
                     dest='use_database',
                     default=False,
                     help='Uses the database to create the test user and for some tests. ' +
                     'Do not use if you do not have access to that environment.')


@pytest.fixture(scope='session', autouse=True)
def set_driver_options(request):
    """ Sets the stage and use_auth options in the BaseDriver class. """
    BaseDriver.stage = request.config.getoption('stage')
    BaseDriver.use_auth = request.config.getoption('use_auth')


@contextmanager
def _driver_manager(request):
    """
    Provides an instance of BaseDriver as a fixture to allow use of other fixtures.
    Mimics the set for the built-in sb fixture from SeleniumBase so that certain SeleniumBase
    features work properly, like screenshots at end of tests & on failure.
    """
    if request.cls:
        request.cls.sb = BaseDriver('base_method')
        request.cls.sb.setUpClass()
        request.cls.sb.setUp()
        request.cls.sb._needs_tearDown = True
        sb_config._sb_node[request.node.nodeid] = request.cls.sb
        yield request.cls.sb
        if request.cls.sb._needs_tearDown:
            request.cls.sb.tearDown()
            request.cls.sb._needs_tearDown = False
    else:
        rdriver = BaseDriver('base_method')
        rdriver.setUpClass()
        rdriver.setUp()
        rdriver._needs_tearDown = True
        sb_config._sb_node[request.node.nodeid] = rdriver
        yield rdriver
        if rdriver._needs_tearDown:
            rdriver.tearDown()
            rdriver._needs_tearDown = False


@pytest.fixture(name='class_driver', scope='class')
def _class_driver(request):
    """ Yields a driver fixture with scope 'class'. """
    with _driver_manager(request) as given_driver:
        given_driver.tearDown = given_driver.tearDownScreenshot
        yield given_driver
        given_driver.tearDownDriver()


@pytest.fixture(name='driver')
def _driver(request):
    """ Yields a driver class with scope 'function'. """
    with _driver_manager(request) as given_driver:
        yield given_driver


@pytest.fixture(name='browser', scope='session')
def _browser(request):
    """ Yields the browser used for the test run. """
    yield request.config.getoption('browser')


@pytest.fixture(scope='session', autouse=True)
def create_test_users(request, start_pennyworth_db_connection):
    """
    Gets login credentials for the test users. If using the database,
    creates the test users with a series of queries to the Pennyworth db.

    Credentials are stored in SSM with the following format:
    {
        "user_type1": {
            "username": "...",
            "password": "...",
            "passhash": "..."
        },
        ...
    }
    """
    all_user_creds = db.get_test_user_credentials(request.config.getoption('stage'))
    for user_type in all_user_creds.keys():
        user_creds = all_user_creds[user_type]
        BaseDriver.USERS_MAP[user_type] = BaseDriver.Credentials(**user_creds)
    if request.config.getoption('use_database'):
        for user_type in all_user_creds.keys():
            user_creds = all_user_creds[user_type]
            BaseDriver.USER_IDS[user_type] = db.setup_user(user_creds['username'],
                                                           user_type,
                                                           user_creds['passhash'])


@pytest.fixture(name='start_pennyworth_db_connection', scope='session', autouse=True)
def _start_pennyworth_db_connection(request):
    """ Starts a connection to the pennyworth db. """
    if request.config.getoption('use_database') or request.config.getoption('use_auth'):
        db.start_connection(request.config.getoption('stage'))
        yield
        db.close_connection()
    # Since the yield above is in a conditional, it doesn't always execute, and when
    # it doesn't, pytest raises a ValueError because it "did not yield a value"
    else:
        yield None


@pytest.fixture(name='standard_feed_types', scope='session', params=[locators.FeedTile.MEDICAL_CONTAINER,
                                                                     locators.FeedTile.RX_CONTAINER])
def _standard_feed_types(request):
    yield request.param


@pytest.fixture(scope='session', autouse=True)
def configure_pytest_report_metadata(request, pytestconfig, browser):
    """ Configures metadata ('Environment' section) for the pytest html report. """
    pytestconfig._metadata['Test Environment'] = request.config.getoption('stage')
    pytestconfig._metadata['Browser'] = browser
