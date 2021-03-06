const token = '';

const authHandlers = [];

window.Twitch = {
  ext: {
    onAuthorized(fn) {
      authHandlers.push(fn);
    },
    onContext() { },
    listen: window.Twitch.ext.listen,
  },
};

window.simulateTwitch = () => {
  authHandlers.forEach(fn => fn({
    token,
    channelId: '27995184',
    userId: '27995184',
  }));
};

