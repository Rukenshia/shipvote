import { dev, browser } from '$app/environment';

declare global {
  interface Window {
    Twitch: any;
  }
}

if (dev && browser) {
  const token = 'aFakeToken';

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
      }
    }
  };

  window.simulateTwitch = () => {
    authHandlers.forEach((fn) =>
      fn({
        token,
        channelId: '1234',
        userId: '2'
      })
    );

    setTimeout(() => {
      window.Twitch.ext.send('broadcast', 'application/json', {
        type: 'vote_status',
        data: { id: 6, status: 'open' }
      });
    }, 500);
  };

  setTimeout(window.simulateTwitch, 100);
}

export {};
