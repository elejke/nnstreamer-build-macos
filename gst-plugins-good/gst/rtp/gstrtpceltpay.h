/* GStreamer
 * Copyright (C) <2009> Wim Taymans <wim.taymans@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more 
 */


#ifndef __GST_RTP_CELT_PAY_H__
#define __GST_RTP_CELT_PAY_H__

#include <gst/gst.h>
#include <gst/rtp/gstrtpbasepayload.h>

G_BEGIN_DECLS

typedef struct _GstRtpCELTPay GstRtpCELTPay;
typedef struct _GstRtpCELTPayClass GstRtpCELTPayClass;

#define GST_TYPE_RTP_CELT_PAY \
  (gst_rtp_celt_pay_get_type())
#define GST_RTP_CELT_PAY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),GST_TYPE_RTP_CELT_PAY,GstRtpCELTPay))
#define GST_RTP_CELT_PAY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass),GST_TYPE_RTP_CELT_PAY,GstRtpCELTPayClass))
#define GST_IS_RTP_CELT_PAY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj),GST_TYPE_RTP_CELT_PAY))
#define GST_IS_RTP_CELT_PAY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass),GST_TYPE_RTP_CELT_PAY))

struct _GstRtpCELTPay
{
  GstRTPBasePayload payload;

  guint64 packet;

  /* queue to hold packets */
  GQueue      *queue;
  guint        sbytes;    /* bytes queued for sizes */
  guint        bytes;     /* bytes queued for data */
  GstClockTime qduration; /* queued duration */
};

struct _GstRtpCELTPayClass
{
  GstRTPBasePayloadClass parent_class;
};

GType gst_rtp_celt_pay_get_type (void);

G_END_DECLS

#endif /* __GST_RTP_CELT_PAY_H__ */
