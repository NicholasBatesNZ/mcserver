const webhookUrl = process.env.WEBHOOK_DISCORD;
import { request } from 'https';
const url = new URL(webhookUrl);

export function handler(event, context, callback) {
  send_message(event);
}


function send_message(events){
  const body = create_message(events);
  const options = {
    host: url.host,
    path: url.pathname,
    port: url.port,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(JSON.stringify(body))
    },
  };
  let req = request(options, (res) => {
    res.on('error', (e) => {
      console.log('problem with request: ' + e.message);
    });
  });
  req.write(JSON.stringify(body));
  req.end();
}

function create_message(events){
  const sns = events.Records[0].Sns;
  
  const data = {
        'embeds': [
            {
                'title': 'AWS Notification: ' + sns.Subject,
                'description': sns.Message,
                'color': 0xFF0000,
                'timestamp': sns.Timestamp,
            }
        ]
    };
  return data;
}
