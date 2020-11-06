"""
Selectors for elements used in the UAT.
Selectors that are just strings are assumed to use By.CSS_SELECTOR
as the selection method, which is the default in SeleniumBase.
"""

from selenium.webdriver.common.by import By


class Feature1:
    """
    Group locators within classes that represent a page or major
    feature on that page, such as the login page or the workspace
    in Marketplace.
    """
    # Locators are assumed to use the CSS_SELECTOR selection method by default
    css_locator = '.classname'
    # Locators that use a different method should be tuples
    # These can be referenced later with *locator for ease in several SeleniumBase method
    non_css_locator = ('Link text', By.LINK_TEXT)
    # For all available selection methods see https://www.selenium.dev/selenium/docs/api/py/webdriver/selenium.webdriver.common.by.html
