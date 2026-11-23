import os
import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service

BASE_URL = os.environ.get("BASE_URL", "http://localhost")
RESULTS = os.environ.get("RESULTS_DIR", "/results")


@pytest.fixture(scope="module")
def driver():
    opts = webdriver.ChromeOptions()
    opts.binary_location = "/usr/bin/chromium"
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--window-size=1000,700")
    drv = webdriver.Chrome(service=Service("/usr/bin/chromedriver"), options=opts)
    drv.get(BASE_URL)
    yield drv
    drv.quit()


def test_title_contains_roll_number(driver):
    assert "FA23-BCT-014" in driver.title


def test_heading_text(driver):
    heading = driver.find_element(By.ID, "heading")
    assert heading.text == "CI/CD Pipeline Demo"


def test_button_click_shows_message(driver):
    driver.find_element(By.ID, "msg-btn").click()
    message = driver.find_element(By.ID, "message")
    assert message.text == "Hello from Jamshaid Fareed!"


def test_textbox_submit_shows_text(driver):
    box = driver.find_element(By.ID, "user-text")
    box.clear()
    box.send_keys("Hello Jenkins")
    driver.find_element(By.ID, "submit-btn").click()
    output = driver.find_element(By.ID, "output")
    assert output.text == "You entered: Hello Jenkins"
    os.makedirs(RESULTS, exist_ok=True)
    driver.save_screenshot(os.path.join(RESULTS, "test_screenshot.png"))


def test_student_info_shown(driver):
    info = driver.find_element(By.ID, "student").text
    assert "Jamshaid Fareed" in info and "FA23-BCT-014" in info
