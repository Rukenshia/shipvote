const token = '***REMOVED***';

const authHandlers = [];

window.Twitch = {
  ext: {
    onAuthorized(fn) {
      authHandlers.push(fn);
    },
    onContext() { },
  },
};

window.simulateTwitch = () => {
  authHandlers.forEach(fn => fn({
    token,
    channelId: '27995184',
    userId: 'fakeUser',
  }));
};

