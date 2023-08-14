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

defineCustomElements();

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

const getCookie = (name) => document.cookie
  .split('; ')
  .find((row) => row.startsWith(`${name}=`))
  ?.split('=')[1];

const accessKeyId = getCookie('accessKeyId');
const secretAccessKey = getCookie('secretAccessKey');

const awsCredentials = {
  region: 'ap-southeast-2',
  credentials: {
    accessKeyId,
    secretAccessKey,
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

const taskFamilies = [...new Set(
  data.ResourceTagMappingList.map(
    (resource) => {
      const [prefix, suffix] = resource.ResourceARN.split('/');
      return `${prefix}/${suffix.split(':')[0]}`;
    },
  ),
)];

const tasks = taskFamilies.map((family) => ({
  arn: family,
  tag: family.split('/')[1],
}));

tasks.forEach((task) => {
  const item = document.createElement('modus-list-item');
  item.appendChild(document.createTextNode(task.tag));
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
        overrides: {
          memory: "15360",
          containerOverrides: [{
            name: 'mcserver',
            memory: 15360,
            environment: [{
              name: 'MAX_HEAP',
              value: '14G',
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
