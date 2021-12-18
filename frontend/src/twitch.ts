import { dev } from '$app/env';

declare global {
  interface Window {
    Twitch: any;
  }
}

if (dev) {
    const token = '';

    const authHandlers = [];
    const listeners = new Map();
    const { listen } = window.Twitch.ext;

    window.Twitch = {
      ext: {
        onAuthorized(fn) {
          authHandlers.push(fn);
        },
        onContext() {},
        listen(target, callback) {
          let targetListeners = [];
          if (listeners.has(target)) {
            targetListeners = listeners.get(target);
          }

          targetListeners.push(callback);

          listeners.set(target, targetListeners);
          listen(target, callback);
        },
        send(target, contentType, message) {
          console.log({ target, contentType, message });
          const targetListeners = listeners.get(target) || [];

          let payload = message;
          if (contentType === 'application/json') {
            payload = btoa(JSON.stringify(message));
          }

          targetListeners.forEach((listener) => {
            listener(target, contentType, payload);
          });
        },
      },
    };

    window.simulateTwitch = () => {
      authHandlers.forEach((fn) =>
        fn({
          token,
          channelId: '27995184',
          userId: '27995184',
        })
      );

      window.Twitch.ext.send('broadcast', 'application/json', { message: 'test' });
    };

    setTimeout(window.simulateTwitch, 100);
}

export {}
