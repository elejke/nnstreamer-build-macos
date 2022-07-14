/* GStreamer
 * Copyright (C) <1999> Erik Walthinsen <omega@cse.ogi.edu>
 * Copyright (C) 2020 Huawei Technologies Co., Ltd.
 *   @Author: Julian Bouzas <julian.bouzas@collabora.com>
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

#include <gst/net/gstnetaddressmeta.h>

#include "gstudpelements.h"

void
udp_element_init (GstPlugin * plugin)
{
  static gsize res = FALSE;
  if (g_once_init_enter (&res)) {
    /* not using GLIB_CHECK_VERSION on purpose, run-time version matters */
    if (glib_check_version (2, 36, 0) != NULL) {
      GST_WARNING ("Your GLib version is < 2.36, UDP multicasting support may "
          "be broken, see https://bugzilla.gnome.org/show_bug.cgi?id=688378");
    }

    /* register info of the netaddress metadata so that we can use it from
     * multiple threads right away. Note that the plugin loading is always
     * serialized */
    gst_net_address_meta_get_info ();
    g_once_init_leave (&res, TRUE);
  }
}
