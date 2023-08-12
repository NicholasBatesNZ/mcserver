import { ECSClient, ListTaskDefinitionsCommand } from '@aws-sdk/client-ecs';
import { defineCustomElements } from '@trimble-oss/modus-web-components/loader';

defineCustomElements();

const darkModeMatcher = window.matchMedia('(prefers-color-scheme: dark)');
const setDarkMode = (bool) => document.documentElement.setAttribute('data-mwc-theme', bool ? 'dark' : 'light');

if (darkModeMatcher.matches) setDarkMode(true);
darkModeMatcher.addEventListener('change', (event) => setDarkMode(event.matches));

const getCookie = (name) => document.cookie
  .split('; ')
  .find((row) => row.startsWith(`${name}=`))
  ?.split('=')[1];

const accessKeyId = getCookie('accessKeyId');
const secretAccessKey = getCookie('secretAccessKey');

const client = new ECSClient({
  region: 'ap-southeast-2',
  credentials: {
    accessKeyId,
    secretAccessKey,
  },
});

const command = new ListTaskDefinitionsCommand();

const response = await client.send(command);

console.log(response);
