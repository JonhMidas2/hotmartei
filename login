import requests
from bs4 import BeautifulSoup
from utils import os, clear_screen, logger


hotmartsession = requests.Session()


def credentials():
  username = input('email: ')
  password = input('senha: ')
  clear_screen()
  return username, password


def get_token(url_token, username, password):
  data = {
    'grant_type': 'password',
    'username': username,
    'password': password
  }
  response = hotmartsession.post(url_token, data=data)

  if response.status_code != 200:
    msg_erro = f'Erro ao acessar {response.url}: Status Code {response.status_code}'
    logger(msg_erro, error=True)
    return None

  return response.json()['access_token']


def check_token(access_token):
  params = {'token': access_token}
  url_check_token = 'https://sec-proxy-content-distribution.hotmart.com/club/security/oauth/check_token'
  response = hotmartsession.get(url_check_token, params=params)
  if response.status_code != 200:
    msg_erro = f'Erro ao acessar {response.url}: Status Code {response.status_code}'
    logger(msg_erro, error=True)
    return None
  response = response.json()['resources']
  courses = {}

  for resource in response:
    resource_info = resource.get('resource', {})
    if resource_info.get('status') == 'ACTIVE' or resource_info.get('status') == 'OVERDUE':
      courses[resource_info['subdomain']] = f'''https://{resource_info['subdomain']}.club.hotmart.com'''

  return courses


def choose_course(courses):
    if not courses or not isinstance(courses, dict):
        print("No valid courses provided.")
        return None, None, None

    print('Courses:')
    for i, course_title in enumerate(courses.keys(), start=1):
        print(f'{i}. {course_title}')

    choice = input('Choose a course by number: ')
    if not choice.isdigit() or not (1 <= int(choice) <= len(courses)):
        print("Invalid choice.")
        return None, None, None

    selected_course_title = list(courses.keys())[int(choice) - 1]
    selected_course_link = courses[selected_course_title]
    print(f'Selected course link: {selected_course_link}')
    print(f'The folder size may cause errors due to excessively long directories.')
    print(f'If you do not specify anything or if the folder does not exist, the download will be done in the folder: {os.getcwd()}.')

    selected_course_folder = input(f'Choose the folder for download: ').strip()
    if not selected_course_folder:
        selected_course_folder = os.getcwd()
    elif not os.path.isdir(selected_course_folder):
        print("The specified folder does not exist. Using the current working directory.")
        selected_course_folder = os.getcwd()

    return selected_course_title, selected_course_link, selected_course_folder


username, password = credentials()
url_token = 'https://sec-proxy-content-distribution.hotmart.com/club/security/oauth/token'
token = get_token(url_token, username, password)
courses = check_token(token)
course_name, course_link, selected_folder = choose_course(courses)
