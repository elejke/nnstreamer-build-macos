/*
 * Copyright (C) 2016 Sebastian Dröge <sebastian@centricular.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gst/gst.h>

#include "gstfdkaac.h"
#include "gstfdkaacenc.h"
#include "gstfdkaacdec.h"

/* *INDENT-OFF* */
const GstFdkAacChannelLayout channel_layouts[] = {
  /* MPEG 1: Mono */
  {1, MODE_1, {GST_AUDIO_CHANNEL_POSITION_MONO}},
  /* MPEG 2: Stereo */
  {2, MODE_2, {
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
  }},
  /* MPEG 3: Stereo + Center */
  {3, MODE_1_2, {
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
  }},
  /* MPEG 4: Stereo + Center + Rear center */
  {4, MODE_1_2_1, {
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_CENTER,
  }},
  /* MPEG 5: 5.0 Surround */
  {5, MODE_1_2_2, { /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
  }},
  {5, MODE_1_2_2, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
  }},
  {5, MODE_1_2_2, { /* Informal, with SIDE; FFmpeg produces this */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_RIGHT,
  }},
  /* MPEG 6: 5.1 Surround */
  {6, MODE_1_2_2_1, { /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {6, MODE_1_2_2_1, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {6, MODE_1_2_2_1, { /* Informal, with SIDE; FFmpeg produces this */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  /* MPEG 7: SDDS for cinema */
  {8, MODE_1_2_2_2_1, { /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {8, MODE_1_2_2_2_1, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  /* Note: 8-channel layouts might also have informal variants with
   * SIDE instead of SURROUND, but they are more complicated. They
   * can be added here if the need arises */
#ifdef HAVE_FDK_AAC_2_0_0
  /* MPEG 11: 6.1 Surround */
  {7, MODE_6_1, { /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_CENTER,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {7, MODE_6_1, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_CENTER,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  /* MPEG 12: 7.1 Surround */
  {8, MODE_7_1_BACK, { /* Informal, with SIDE */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {8, MODE_7_1_BACK, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  /* MPEG 14: 5.1.2 Surround */
  {8, MODE_7_1_TOP_FRONT, { /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
    GST_AUDIO_CHANNEL_POSITION_TOP_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_TOP_FRONT_RIGHT,
  }},
  {8, MODE_7_1_TOP_FRONT, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
    GST_AUDIO_CHANNEL_POSITION_TOP_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_TOP_FRONT_RIGHT,
  }},
#endif
#ifdef HAVE_FDK_AAC_0_1_4
  /* Non-standard PCE clone of mode 12 */
  {8, MODE_7_1_REAR_SURROUND, { /* Informal, with SIDE */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SIDE_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {8, MODE_7_1_REAR_SURROUND, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  /* Non-standard PCE clone of mode 7 */
  {8, MODE_7_1_FRONT_CENTER,{ /* Informal, with REAR */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_REAR_LEFT,
    GST_AUDIO_CHANNEL_POSITION_REAR_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
  {8, MODE_7_1_FRONT_CENTER, { /* Formal, with SURROUND */
    GST_AUDIO_CHANNEL_POSITION_FRONT_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
    GST_AUDIO_CHANNEL_POSITION_FRONT_LEFT,
    GST_AUDIO_CHANNEL_POSITION_FRONT_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_LEFT,
    GST_AUDIO_CHANNEL_POSITION_SURROUND_RIGHT,
    GST_AUDIO_CHANNEL_POSITION_LFE1,
  }},
#endif
  /* Iteration sentinel */
  {0, MODE_INVALID, {GST_AUDIO_CHANNEL_POSITION_INVALID}},
};
/* *INDENT-ON* */
