import {
  ResourceGroupsTaggingAPIClient,
  GetResourcesCommand,
} from '@aws-sdk/client-resource-groups-tagging-api';
import {
  ECSClient,
  ListTasksCommand,
  RunTaskCommand,
  StopTaskCommand,
} from '@aws-sdk/client-ecs';
import { defineCustomElements } from '@trimble-oss/modus-web-components/loader';

const getCookie = (name) => document.cookie
  .split('; ')
  .find((row) => row.startsWith(`${name}=`))
  ?.split('=')[1];

const accessKeyId = getCookie('aws_access_key_id');
const secretAccessKey = getCookie('aws_secret_access_key');
const sessionToken = getCookie('aws_session_token');

defineCustomElements().then(() => {
  if (!accessKeyId || !secretAccessKey) {
    document.querySelector('modus-modal').open();

    document.querySelector('modus-file-dropzone').addEventListener('files', (event) => {
      const [files] = event.detail;
      const reader = new FileReader();
      reader.readAsText(files[0]);

      reader.onload = (content) => {
        const lines = content.target.result.split('\n');
        if (files[0].name === 'credentials') {
          document.cookie = lines[1].replaceAll(' ', '');
          document.cookie = lines[2].replaceAll(' ', '');
        } else {
          const [key, secret] = lines[1].split(',');
          document.cookie = `aws_access_key_id=${key}`;
          document.cookie = `aws_secret_access_key=${secret}`;
        }
        window.location.reload();
      };
    });
  }
});

const state = new Proxy({}, {
  set(target, prop, value) {
    target[prop] = value;
    if (prop === 'selectedTask') setSelectedTask(value);
    return true;
  },
});

const darkModeMatcher = window.matchMedia('(prefers-color-scheme: dark)');
const setDarkMode = (bool) => document.documentElement.setAttribute('data-mwc-theme', bool ? 'dark' : 'light');

if (darkModeMatcher.matches) setDarkMode(true);
darkModeMatcher.addEventListener('change', (event) => setDarkMode(event.matches));

const awsCredentials = {
  region: 'ap-southeast-2',
  credentials: {
    accessKeyId,
    secretAccessKey,
    sessionToken,
  },
};

const taggingClient = new ResourceGroupsTaggingAPIClient(awsCredentials);

const data = await taggingClient.send(
  new GetResourcesCommand({
    ResourceTypeFilters: ['ecs:task-definition'],
    TagFilters: [{
      Key: 'ryanFriendly',
      Values: ['yes'],
    }],
  }),
);

const taskFamilies = data.ResourceTagMappingList
  .map(
    (resource) => {
      const [prefix, suffix] = resource.ResourceARN.split('/');
      const version = resource.Tags.filter((tag) => tag.Key === 'McVersion')[0];
      return {
        arn: `${prefix}/${suffix.split(':')[0]}`,
        version: version?.Value ?? '1.?.?',
      };
    },
  )
  .filter((value, index, self) => index === self
    .findIndex((entry) => entry.arn === value.arn && entry.version === value.version));

const tasks = taskFamilies.map(({ arn, version }) => ({
  arn,
  version,
  tag: arn.split('/')[1],
}));

tasks.sort((a, b) => a.tag.localeCompare(b.tag));

tasks.forEach((task) => {
  const item = document.createElement('modus-list-item');
  item.appendChild(document.createTextNode(`${task.tag} | ${task.version}`));
  item.onclick = () => { state.selectedTask = task; };
  document.querySelector('#taskList').appendChild(item);
});

const ecsClient = new ECSClient(awsCredentials);

const allRunningTasks = await ecsClient.send(
  new ListTasksCommand({
    cluster: 'DevCluster',
  }),
);
state.taskRunning = allRunningTasks.taskArns.length > 0;
if (allRunningTasks.taskArns.length > 0) {
  // eslint-disable-next-line prefer-destructuring
  state.taskId = allRunningTasks.taskArns[0].split('/')[2];
}

const setSelectedTask = async (task) => {
  document.querySelector('#runTaskToggle').setAttribute('disabled', true);
  document.querySelector('#toggleButton').textContent = task.tag;

  const response = await ecsClient.send(
    new ListTasksCommand({
      cluster: 'DevCluster',
      family: task.tag,
    }),
  );

  document.querySelector('#runTaskToggle').setAttribute('checked', response.taskArns.length > 0);
  if (response.taskArns.length > 0) {
    state.taskRunning = true;
    // eslint-disable-next-line prefer-destructuring
    state.taskId = response.taskArns[0].split('/')[2];
    document.querySelector('#runTaskToggle').setAttribute('disabled', false);
  } else {
    document.querySelector('#runTaskToggle').setAttribute('disabled', state.taskRunning);
  }
};

document.addEventListener('switchClick', async (event) => {
  if (event.detail) {
    const response = await ecsClient.send(
      new RunTaskCommand({
        cluster: 'DevCluster',
        taskDefinition: state.selectedTask.arn,
        enableExecuteCommand: true,
        overrides: {
          taskRoleArn: 'arn:aws:iam::251780365797:role/ecsTaskExecutionRole',
          memory: '3584',
          containerOverrides: [{
            name: 'mcserver',
            memory: 3584,
            environment: [{
              name: 'MAX_HEAP',
              value: '3G',
            }],
          }],
        },
      }),
    );
    state.taskRunning = true;
    // eslint-disable-next-line prefer-destructuring
    state.taskId = response.tasks[0].taskArn.split('/')[2];
  } else {
    await ecsClient.send(
      new StopTaskCommand({
        cluster: 'DevCluster',
        task: state.taskId,
      }),
    );
    state.taskRunning = false;
  }
});
