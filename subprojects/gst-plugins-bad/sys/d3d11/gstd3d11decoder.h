/* GStreamer
 * Copyright (C) 2019 Seungha Yang <seungha.yang@navercorp.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef __GST_D3D11_DECODER_H__
#define __GST_D3D11_DECODER_H__

#include <gst/gst.h>
#include <gst/video/video.h>
#include <gst/d3d11/gstd3d11.h>

G_BEGIN_DECLS

#define GST_TYPE_D3D11_DECODER (gst_d3d11_decoder_get_type())
G_DECLARE_FINAL_TYPE (GstD3D11Decoder,
    gst_d3d11_decoder, GST, D3D11_DECODER, GstObject);

typedef struct _GstD3D11DecoderClassData GstD3D11DecoderClassData;

typedef enum
{
  GST_DXVA_CODEC_NONE,
  GST_DXVA_CODEC_MPEG2,
  GST_DXVA_CODEC_H264,
  GST_DXVA_CODEC_H265,
  GST_DXVA_CODEC_VP8,
  GST_DXVA_CODEC_VP9,
  GST_DXVA_CODEC_AV1,

  /* the last of supported codec */
  GST_DXVA_CODEC_LAST
} GstDXVACodec;

typedef struct
{
  guint adapter;
  guint device_id;
  guint vendor_id;
} GstD3D11DecoderSubClassData;

typedef struct _GstD3D11DecodeInputStreamArgs
{
  gpointer picture_params;
  gsize picture_params_size;

  gpointer slice_control;
  gsize slice_control_size;

  gpointer bitstream;
  gsize bitstream_size;

  gpointer inverse_quantization_matrix;
  gsize inverse_quantization_matrix_size;
} GstD3D11DecodeInputStreamArgs;

GstD3D11Decoder * gst_d3d11_decoder_new (GstD3D11Device * device,
                                         GstDXVACodec codec);

gboolean          gst_d3d11_decoder_is_configured (GstD3D11Decoder * decoder);

gboolean          gst_d3d11_decoder_configure     (GstD3D11Decoder * decoder,
                                                   GstVideoCodecState * input_state,
                                                   GstVideoInfo * info,
                                                   gint coded_width,
                                                   gint coded_height,
                                                   guint dpb_size);

gboolean          gst_d3d11_decoder_decode_frame  (GstD3D11Decoder * decoder,
                                                   ID3D11VideoDecoderOutputView * output_view,
                                                   GstD3D11DecodeInputStreamArgs * input_args);


GstBuffer *       gst_d3d11_decoder_get_output_view_buffer (GstD3D11Decoder * decoder,
                                                            GstVideoDecoder * videodec);

ID3D11VideoDecoderOutputView * gst_d3d11_decoder_get_output_view_from_buffer (GstD3D11Decoder * decoder,
                                                                              GstBuffer * buffer,
                                                                              guint8 * view_id);

gboolean          gst_d3d11_decoder_process_output      (GstD3D11Decoder * decoder,
                                                         GstVideoDecoder * videodec,
                                                         gint display_width,
                                                         gint display_height,
                                                         GstBuffer * decoder_buffer,
                                                         GstBuffer ** output);

gboolean          gst_d3d11_decoder_negotiate           (GstD3D11Decoder * decoder,
                                                         GstVideoDecoder * videodec);

gboolean          gst_d3d11_decoder_decide_allocation   (GstD3D11Decoder * decoder,
                                                         GstVideoDecoder * videodec,
                                                         GstQuery * query);

gboolean          gst_d3d11_decoder_set_flushing        (GstD3D11Decoder * decoder,
                                                         GstVideoDecoder * videodec,
                                                         gboolean flushing);

/* Utils for class registration */
typedef struct _GstDXVAResolution
{
  guint width;
  guint height;
} GstDXVAResolution;

static const GstDXVAResolution gst_dxva_resolutions[] = {
  {1920, 1088}, {2560, 1440}, {3840, 2160}, {4096, 2160},
  {7680, 4320}, {8192, 4320}
};

gboolean          gst_d3d11_decoder_util_is_legacy_device (GstD3D11Device * device);

gboolean          gst_d3d11_decoder_get_supported_decoder_profile (GstD3D11Device * device,
                                                                   GstDXVACodec codec,
                                                                   GstVideoFormat format,
                                                                   const GUID ** selected_profile);

gboolean          gst_d3d11_decoder_supports_format (GstD3D11Device * device,
                                                     const GUID * decoder_profile,
                                                     DXGI_FORMAT format);

gboolean          gst_d3d11_decoder_supports_resolution (GstD3D11Device * device,
                                                         const GUID * decoder_profile,
                                                         DXGI_FORMAT format,
                                                         guint width,
                                                         guint height);

GstD3D11DecoderClassData *  gst_d3d11_decoder_class_data_new  (GstD3D11Device * device,
                                                               GstDXVACodec codec,
                                                               GstCaps * sink_caps,
                                                               GstCaps * src_caps);

void  gst_d3d11_decoder_class_data_fill_subclass_data (GstD3D11DecoderClassData * data,
                                                       GstD3D11DecoderSubClassData * subclass_data);

void  gst_d3d11_decoder_proxy_class_init              (GstElementClass * klass,
                                                       GstD3D11DecoderClassData * data,
                                                       const gchar * author);

void  gst_d3d11_decoder_proxy_get_property            (GObject * object,
                                                       guint prop_id,
                                                       GValue * value,
                                                       GParamSpec * pspec,
                                                       GstD3D11DecoderSubClassData * subclass_data);

G_END_DECLS

#endif /* __GST_D3D11_DECODER_H__ */
