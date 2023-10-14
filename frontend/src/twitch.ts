const dev = import.meta.env.DEV;

declare global {
  interface Window {
    Twitch: any;
  }
}

if (dev) {
  const token = "aFakeToken";

  const authHandlers = [];
  const contextHandlers = [];
  const listeners = new Map();
  const { listen } = window.Twitch.ext;

  window.Twitch = {
    ext: {
      onAuthorized(fn) {
        authHandlers.push(fn);
      },
      onContext(fn) {
        contextHandlers.push(fn);
      },
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
        const targetListeners = listeners.get(target) || [];

        let payload = message;
        if (contentType === "application/json") {
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
        channelId: "1234",
        userId: "2",
      }),
    );

    contextHandlers.forEach((fn) =>
      fn({
        theme: "dark",
        language: "en",
        game: "World of Warships",
      }),
    );
  };

  setTimeout(window.simulateTwitch, 100);
}

export {};
