import { get, post, patch } from 'axios';

export class ShipvoteApi {
  constructor(baseUrl, token, channelId) {
    this.baseUrl = baseUrl;
    this.token = token;
    this.channelId = channelId;
  }

  headers() {
    return {
      'Content-Type': 'application/json',
      authorization: `Bearer ${this.token}`,
    };
  }

  buildUrl(path) {
    return `${this.baseUrl}/api/channels/${this.channelId}${path}`;
  }

  buildNewUrl(path) {
    return `https://api.shipvote.in.fkn.space/api/channels/${this.channelId}${path}`;
  }

  getChannelInfo() {
    return get(this.buildUrl('/'), { headers: this.headers() }).then(
      (res) => res.data.data
    );
  }

  getWarships(ids) {
    return get(`https://in.fkn.space/shipvote/warships.json`).then((res) => {
      console.log(res.data.data, ids);
      return res.data.data.filter((s) => ids.includes(s.id));
    });
  }

  getOpenVote() {
    return get(this.buildUrl('/votes?status=open'), {
      headers: this.headers(),
    }).then((res) => res.data.data[0]);
  }

  getClosedVotes() {
    return get(this.buildUrl('/votes?status=closed'), {
      headers: this.headers(),
    }).then((res) => res.data.data);
  }

  getVote(id, full = true) {
    return get(this.buildUrl(`/votes/${id}?full=${full}`), {
      headers: this.headers(),
    }).then((res) => res.data.data);
  }

  openVote(ships) {
    return post(
      this.buildNewUrl('/votes'),
      { vote: { ships, status: 'open' } },
      { headers: this.headers() }
    ).then((res) => res.data.data);
  }

  closeVote(voteId) {
    return patch(
      this.buildNewUrl(`/votes/${voteId}/status`),
      { status: 'closed' },
      { headers: this.headers() }
    ).then((res) => res.data.data);
  }

  voteForShip(voteId, shipId) {
    return post(
      this.buildNewUrl(`/votes/${voteId}/submit`),
      { ship_id: shipId },
      { headers: this.headers() }
    );
  }
}
