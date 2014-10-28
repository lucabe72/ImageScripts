static inline gro_result_t nena_receive(struct napi_struct *napi, struct sk_buff *skb)
{
	int ret = netif_receive_skb(skb);
	if (ret == NET_RX_DROP) {
//	FIXME!!!		adapter->rx_dropped_backlog++;
	}

	return ret;
}

static inline int nena_schedule_prep(struct napi_struct *n)
{
	return 1;
}

static inline __attribute__((always_inline)) void nena_schedule(struct napi_struct *n)
{
	while (n->poll(n, n->weight) == n->weight) {
		local_bh_enable();
		local_bh_disable();
	}
}

static inline void nena_complete(struct napi_struct *n)
{
}

static inline void nena_add(struct net_device *dev, struct napi_struct *napi,
                    int (*poll)(struct napi_struct *, int), int weight)
{
        INIT_LIST_HEAD(&napi->poll_list);
        napi->gro_count = 0;
        napi->gro_list = NULL;
        napi->skb = NULL;
        napi->poll = poll;
        napi->weight = weight;
        napi->dev = dev;
}


#define napi_gro_receive nena_receive
#define napi_schedule_prep nena_schedule_prep
#define __napi_schedule nena_schedule
#define napi_complete nena_complete
//#define netif_napi_add nena_add
