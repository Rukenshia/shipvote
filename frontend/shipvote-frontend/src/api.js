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
      authorization: `Bearer ${this.token}`
    };
  }

  buildUrl(path) {
    return `${this.baseUrl}/api/channels/${this.channelId}${path}`;
  }

  getChannelInfo() {
    return get(this.buildUrl('/'), { headers: this.headers() })
      .then(res => res.data.data);
  }

  getWarships(ids) {
    return get(`${this.baseUrl}/api/warships`, {
      headers: this.headers(),
      params: { ids }
    })
      .then(res => res.data.data);
  }

  getOpenVote() {
    return get(this.buildUrl('/votes?status=open'), { headers: this.headers() })
      .then(res => res.data.data[0]);
  }

  getVote(id) {
    return get(this.buildUrl(`/votes/${id}`), { headers: this.headers() })
      .then(res => res.data.data);
  }

  openVote(ships) {
    return post(this.buildUrl('/votes'), { vote: { ships, status: 'open' } }, { headers: this.headers() })
      .then(res => res.data.data);
  }

  closeVote(voteId) {
    return patch(this.buildUrl(`/votes/${voteId}/status`), { status: 'closed' }, { headers: this.headers() })
      .then(res => res.data.data);
  }

  voteForShip(voteId, shipId) {
    return post(this.buildUrl(`/votes/${voteId}/submit`), { ship_id: shipId }, { headers: this.headers() });
  }
}
