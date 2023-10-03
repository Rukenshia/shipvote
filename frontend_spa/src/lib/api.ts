import axios from 'axios';
import type { AxiosResponse } from 'axios';

export interface Ship {
  id: number;
  name: string;
  nation: string;
  type: string;
  tier: string;
  premium: boolean;
  image: string;

  enabled: boolean;
}

export interface Channel {
  id: number;
  wows_username?: string;
  wows_account_id?: number;
  wows_realm?: string;
  ships?: Ship[];
}

export interface Vote {
  id: number;
  channel_id: number;
  status: string;
  ships: number[];
  votes: { [id: number]: number };
  updated_at: Date;
}

export class ShipvoteApi {
  constructor(private baseUrl: string, private token: string, private channelId: string) { }

  headers() {
    return {
      'Content-Type': 'application/json',
      authorization: `Bearer ${this.token}`
    };
  }

  buildUrl(path: string) {
    return `${this.baseUrl}/api/channels/${this.channelId}${path}`;
  }

  buildBroadcasterUrl(path: string) {
    return `${this.baseUrl}/api/settings/channels/${this.channelId}${path}`;
  }

  async createChannelConfig(channel: Channel): Promise<Channel> {
    return axios
      .post(`${this.baseUrl}/api/settings/channels`, channel, {
        headers: this.headers()
      })
      .then((res: AxiosResponse) => res.data.data);
  }

  async updateChannelConfig(channel: Channel): Promise<Channel> {
    return axios
      .put(
        this.buildBroadcasterUrl('/'),
        { channel },
        {
          headers: this.headers()
        }
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async setShipStatus(id: number, enabled: boolean): Promise<Ship> {
    return axios.put(
      this.buildBroadcasterUrl(`/ships/${id}/enabled`),
      { enabled },
      {
        headers: this.headers()
      }
    );
  }

  async broadcasterGetChannel(): Promise<Channel> {
    return axios
      .get(this.buildBroadcasterUrl('/'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getChannelInfo(): Promise<Channel> {
    return axios
      .get(this.buildUrl('/'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getAllWarships(): Promise<Ship[]> {
    return axios
      .get(`https://in.fkn.space/shipvote/warships.json`)
      .then((response) => response.data.data);
  }

  async getWarships(ids: number[]): Promise<Ship[]> {
    return this.getAllWarships().then((ships: Ship[]) =>
      ships.filter((s: Ship) => ids.includes(s.id))
    );
  }

  async getOpenVote(): Promise<Vote> {
    return axios
      .get(this.buildUrl('/votes?status=open'), { headers: this.headers() })
      .then((res: AxiosResponse) => (res.data.data.length > 0 ? res.data.data[0] : undefined));
  }

  async getClosedVotes(): Promise<Vote[]> {
    return axios
      .get(this.buildUrl('/votes?status=closed'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getVote(id: number, full = true): Promise<Vote> {
    return axios
      .get(this.buildUrl(`/votes/${id}?full=${full}`), {
        headers: this.headers()
      })
      .then((res: AxiosResponse) => res.data.data);
  }

  async openVote(ships: number[]): Promise<Vote> {
    return axios
      .post(
        this.buildUrl('/votes'),
        { vote: { ships, status: 'open' } },
        { headers: this.headers() }
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async closeVote(voteId: number): Promise<Vote> {
    return axios
      .patch(
        this.buildUrl(`/votes/${voteId}/status`),
        { status: 'closed' },
        { headers: this.headers() }
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  voteForShip(voteId: number, shipId: number): Promise<void> {
    return axios.post(
      this.buildUrl(`/votes/${voteId}/submit`),
      { ship_id: shipId },
      { headers: this.headers() }
    );
  }
}
