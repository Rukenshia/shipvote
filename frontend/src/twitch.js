window.Twitch.ext.onContext((context, changes) => {
    console.log(context);
});

window.Twitch.ext.onAuthorized((data) => {
    console.log(data);
});

window.Twitch.ext.actions.requestIdShare();