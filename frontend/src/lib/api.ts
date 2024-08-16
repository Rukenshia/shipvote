import axios from "axios";
import type { AxiosResponse } from "axios";

export type ShipId = number;
export interface Ship {
  id: ShipId;
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
  overlay_position: string;
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
  started_at: Date;
  ends_at?: Date;
  updated_at: Date;
}

export class ShipvoteApi {
  constructor(
    private baseUrl: string,
    private token: string,
    private channelId: string,
  ) { }

  headers() {
    return {
      "Content-Type": "application/json",
      authorization: `Bearer ${this.token}`,
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
        headers: this.headers(),
      })
      .then((res: AxiosResponse) => res.data.data);
  }

  async updateChannelConfig(channel: Channel): Promise<Channel> {
    return axios
      .put(
        this.buildBroadcasterUrl("/"),
        { channel },
        {
          headers: this.headers(),
        },
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async setShipStatus(id: number, enabled: boolean): Promise<Ship> {
    return axios.put(
      this.buildBroadcasterUrl(`/ships/${id}/enabled`),
      { enabled },
      {
        headers: this.headers(),
      },
    );
  }

  async broadcasterGetChannel(): Promise<Channel> {
    return axios
      .get(this.buildBroadcasterUrl("/"), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getChannelInfo(): Promise<Channel> {
    return axios
      .get(this.buildUrl("/"), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getAllWarships(): Promise<Ship[]> {
    return axios
      .get(`https://in.fkn.space/shipvote/warships.json`)
      .then((response) => response.data.data);
  }

  async getWarships(ids: number[]): Promise<Ship[]> {
    return this.getAllWarships().then((ships: Ship[]) =>
      ships.filter((s: Ship) => ids.includes(s.id)),
    );
  }

  async getOpenVote(): Promise<Vote> {
    return axios
      .get(this.buildUrl("/votes?status=open"), { headers: this.headers() })
      .then((res: AxiosResponse) =>
        res.data.data.length > 0 ? res.data.data[0] : undefined,
      );
  }

  async getClosedVotes(): Promise<Vote[]> {
    return axios
      .get(this.buildUrl("/votes?status=closed"), { headers: this.headers() })
      .then((res: AxiosResponse) => res.data.data);
  }

  async getVote(id: number, full = true): Promise<Vote> {
    return axios
      .get(this.buildUrl(`/votes/${id}?full=${full}`), {
        headers: this.headers(),
      })
      .then((res: AxiosResponse) => res.data.data);
  }

  async openVote(ships: number[], duration = undefined): Promise<Vote> {
    let end_date = undefined;
    if (duration) {
      const now = new Date();
      end_date = new Date(now.getTime() + duration * 60000);
      end_date = end_date.toISOString();
    }
    return axios
      .post(
        this.buildUrl("/votes"),
        { vote: { ships, status: "open", scheduled_end: end_date } },
        { headers: this.headers() },
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async closeVote(voteId: number): Promise<Vote> {
    return axios
      .patch(
        this.buildUrl(`/votes/${voteId}/status`),
        { status: "closed" },
        { headers: this.headers() },
      )
      .then((res: AxiosResponse) => res.data.data);
  }

  async sendFeedback(feedback: string): Promise<void> {
    return axios.post(
      this.buildBroadcasterUrl("/feedback"),
      { feedback: { channelId: this.channelId, message: feedback } },
      { headers: this.headers() },
    );
  }

  voteForShip(voteId: number, shipId: number): Promise<void> {
    return axios.post(
      this.buildUrl(`/votes/${voteId}/submit`),
      { ship_id: shipId },
      { headers: this.headers() },
    );
  }
}
