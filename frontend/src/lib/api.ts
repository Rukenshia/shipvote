import axios, { AxiosResponse } from 'axios';

export interface Ship {
  id: number;
  name: string;
  nation: string;
  type: string;
  tier: string;
  premium: boolean;
  image: string;
}

export interface Channel {
  id: number;
  wows_username: string;
  wows_account_id: number;
  wows_realm: string;
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
  constructor(
    private baseUrl: string,
    private token: string,
    private channelId: string
  ) {}

  headers() {
    return {
      'Content-Type': 'application/json',
      authorization: `Bearer ${this.token}`,
    };
  }

  buildUrl(path: string) {
    return `${this.baseUrl}/api/channels/${this.channelId}${path}`;
  }

  buildNewUrl(path: string) {
    return `https://shipvote.in.fkn.space/api/channels/${this.channelId}${path}`;
  }

  async getChannelInfo(): Promise<Channel> {
    return axios
      .get(this.buildUrl('/'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getAllWarships(): Promise<Ship[]> {
    return axios
      .get(`https://in.fkn.space/shipvote/warships.json`)
      .then(response => response.data.data);
  }

  async getWarships(ids: number[]): Promise<Ship[]> {
    return this.getAllWarships().then((ships: Ship[]) =>
        ships.filter((s: Ship) => ids.includes(s.id))
      );
  }

  async getOpenVote(): Promise<Vote> {
    return axios
      .get(this.buildUrl('/votes?status=open'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data[0]);
  }

  async getClosedVotes(): Promise<Vote[]> {
    return axios
      .get(this.buildUrl('/votes?status=closed'), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getVote(id: number, full = true): Promise<Vote> {
    return axios
      .get(this.buildUrl(`/votes/${id}?full=${full}`), {
        headers: this.headers(),
      })
      .then((res: AxiosResponse) => res.data.data);
  }

  async openVote(ships: number[]): Promise<Vote> {
    return axios
      .post(
        this.buildNewUrl('/votes'),
        { vote: { ships, status: 'open' } },
        { headers: this.headers() }
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async closeVote(voteId: number): Promise<Vote> {
    return axios
      .patch(
        this.buildNewUrl(`/votes/${voteId}/status`),
        { status: 'closed' },
        { headers: this.headers() }
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  voteForShip(voteId: number, shipId: number): Promise<void> {
    return axios.post(
      this.buildNewUrl(`/votes/${voteId}/submit`),
      { ship_id: shipId },
      { headers: this.headers() }
    );
  }
}
