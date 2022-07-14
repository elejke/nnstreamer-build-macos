/* Small helper element for format conversion
 * Copyright (C) 2005 Tim-Philipp Müller <tim centricular net>
 * Copyright (C) 2010 Brandon Lewis <brandon.lewis@collabora.co.uk>
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
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gst/gst.h>
#include <gst/video/video.h>
#include "ges-screenshot.h"
#include "ges-internal.h"

/**
 * ges_play_sink_convert_frame:
 * @playsink: The playsink to get last frame from
 * @caps: The caps defining the format the return value will have
 *
 * Get the last buffer @playsink showed
 *
 * Returns: (transfer full): A #GstSample containing the last frame from
 * @playsink in the format defined by the @caps
 *
 * Deprecated: 1.18: Use the "convert-sample" action signal of
 * #playsink instead.
 */
GstSample *
ges_play_sink_convert_frame (GstElement * playsink, GstCaps * caps)
{
  GstSample *sample = NULL;

  g_signal_emit_by_name (playsink, "convert-sample", caps, &sample);

  return sample;
}
